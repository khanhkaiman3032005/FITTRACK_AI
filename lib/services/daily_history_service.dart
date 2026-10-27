import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/daily_record.dart';
import 'nutrition_service.dart';
import 'health_service.dart';
import 'workout_service.dart';

import '../models/weekly_report.dart';

class DailyHistoryService {
  DailyHistoryService._();

  static String _storageKeyForUser(String userId) {
    return 'daily_history_$userId';
  }

  static final Map<String, DailyRecord> _records = {};

  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);

  static String dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static Future<void> loadData() async {
    final user = Supabase.instance.client.auth.currentUser;

    _records.clear();

    // Chưa đăng nhập -> không load lịch sử của bất kỳ tài khoản nào.
    if (user == null) {
      notifier.value++;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final storageKey = _storageKeyForUser(user.id);

    // 1. Load cache local của đúng tài khoản trước.
    final savedData = prefs.getString(storageKey);

    if (savedData != null && savedData.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(savedData);

        decoded.forEach((key, value) {
          _records[key] = DailyRecord.fromJson(
            Map<String, dynamic>.from(value),
          );
        });
      } catch (e) {
        debugPrint('Lỗi load DailyHistory local: $e');
      }
    }

    // 2. Sau đó lấy dữ liệu mới nhất từ Supabase.
    try {
      final response = await Supabase.instance.client
          .from('daily_records')
          .select()
          .eq('user_id', user.id)
          .order('record_date');

      _records.clear();

      for (final row in response) {
        final record = _fromSupabase(Map<String, dynamic>.from(row));

        _records[dateKey(record.date)] = record;
      }

      // Cache dữ liệu Supabase xuống thiết bị.
      await _saveData();

      debugPrint(
        'DailyHistory: loaded ${_records.length} records from Supabase',
      );
    } catch (e) {
      // Nếu mất mạng thì vẫn giữ cache local đã load phía trên.
      debugPrint('DailyHistory Supabase load error: $e');
    }

    notifier.value++;
  }

  static Future<void> _saveData() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{};

    _records.forEach((key, record) {
      data[key] = record.toJson();
    });

    await prefs.setString(_storageKeyForUser(user.id), jsonEncode(data));
  }

  static Map<String, dynamic> _toSupabase({
    required String userId,
    required DailyRecord record,
  }) {
    return {
      'user_id': userId,
      'record_date': dateKey(record.date),
      'calories_intake': record.caloriesIntake,
      'calories_burned': record.caloriesBurned,
      'steps': record.steps,
      'workout_minutes': record.workoutMinutes,
      'completed_exercises': record.completedExercises,
      'water': record.water,
      'bmi': record.bmi,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  static DailyRecord _fromSupabase(Map<String, dynamic> row) {
    return DailyRecord(
      date: DateTime.parse(row['record_date'].toString()),
      caloriesIntake: (row['calories_intake'] ?? 0) as int,
      caloriesBurned: (row['calories_burned'] ?? 0) as int,
      steps: (row['steps'] ?? 0) as int,
      workoutMinutes: (row['workout_minutes'] ?? 0) as int,
      completedExercises: (row['completed_exercises'] ?? 0) as int,
      water: (row['water'] ?? 0).toDouble(),
      bmi: (row['bmi'] ?? 0).toDouble(),
    );
  }

  static DailyRecord? getRecord(DateTime date) {
    return _records[dateKey(date)];
  }

  static List<DailyRecord> getRecentRecords({int days = 7}) {
    final now = DateTime.now();

    final records = <DailyRecord>[];

    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));

      final record = getRecord(date);

      if (record != null) {
        records.add(record);
      }
    }

    return records;
  }

  static WeeklyReport getWeeklyReport() {
    final records = getRecentRecords(days: 7);

    if (records.isEmpty) {
      return const WeeklyReport(
        daysWithData: 0,
        totalCaloriesIntake: 0,
        totalCaloriesBurned: 0,
        totalSteps: 0,
        totalWorkoutMinutes: 0,
        totalCompletedExercises: 0,
        averageCaloriesIntake: 0,
        averageCaloriesBurned: 0,
        averageSteps: 0,
        averageWorkoutMinutes: 0,
        averageWater: 0,
        mostActiveDay: null,
        leastActiveDay: null,
      );
    }

    int totalCaloriesIntake = 0;
    int totalCaloriesBurned = 0;
    int totalSteps = 0;
    int totalWorkoutMinutes = 0;
    int totalCompletedExercises = 0;
    double totalWater = 0;

    for (final record in records) {
      totalCaloriesIntake += record.caloriesIntake;
      totalCaloriesBurned += record.caloriesBurned;
      totalSteps += record.steps;
      totalWorkoutMinutes += record.workoutMinutes;
      totalCompletedExercises += record.completedExercises;
      totalWater += record.water;
    }

    DailyRecord mostActiveDay = records.first;
    DailyRecord leastActiveDay = records.first;

    for (final record in records.skip(1)) {
      if (record.steps > mostActiveDay.steps) {
        mostActiveDay = record;
      }

      if (record.steps < leastActiveDay.steps) {
        leastActiveDay = record;
      }
    }

    final days = records.length;

    return WeeklyReport(
      daysWithData: days,
      totalCaloriesIntake: totalCaloriesIntake,
      totalCaloriesBurned: totalCaloriesBurned,
      totalSteps: totalSteps,
      totalWorkoutMinutes: totalWorkoutMinutes,
      totalCompletedExercises: totalCompletedExercises,
      averageCaloriesIntake: totalCaloriesIntake / days,
      averageCaloriesBurned: totalCaloriesBurned / days,
      averageSteps: totalSteps / days,
      averageWorkoutMinutes: totalWorkoutMinutes / days,
      averageWater: totalWater / days,
      mostActiveDay: mostActiveDay,
      leastActiveDay: leastActiveDay,
    );
  }

  static DailyRecord getRecordOrEmpty(DateTime date) {
    final key = dateKey(date);

    return _records[key] ??
        DailyRecord(
          date: DateTime(date.year, date.month, date.day),
          caloriesIntake: 0,
          caloriesBurned: 0,
          steps: 0,
          workoutMinutes: 0,
          completedExercises: 0,
          water: 0,
          bmi: 0,
        );
  }

  static Future<void> saveRecord(DailyRecord record) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập.');
    }

    // 1. Lưu Supabase trước.
    await Supabase.instance.client
        .from('daily_records')
        .upsert(
          _toSupabase(userId: user.id, record: record),
          onConflict: 'user_id,record_date',
        );

    // 2. Supabase thành công mới cập nhật local.
    _records[dateKey(record.date)] = record;

    await _saveData();

    notifier.value++;

    debugPrint('DailyHistory: saved ${dateKey(record.date)} to Supabase');
  }

  static Future<void> saveTodaySnapshot() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập.');
    }

    await HealthService.ensureCurrentDay();
    await WorkoutService.ensureCurrentDay();

    final now = DateTime.now();

    final today = dateKey(now);

    // Lấy record hiện tại trên Supabase trước để tránh
    // ghi đè dữ liệu mới bằng state cũ từ một service khác.
    final existing = await Supabase.instance.client
        .from('daily_records')
        .select()
        .eq('user_id', user.id)
        .eq('record_date', today)
        .maybeSingle();

    final current = existing == null
        ? null
        : _fromSupabase(Map<String, dynamic>.from(existing));

    final record = DailyRecord(
      date: DateTime(now.year, now.month, now.day),

      // Nutrition là nguồn chính cho calories nạp.
      caloriesIntake: NutritionService.totalCaloriesForDate(now),

      // WorkoutService là nguồn chính cho workout.
      caloriesBurned: WorkoutService.caloriesBurnedToday,
      completedExercises: WorkoutService.completedToday,

      // HealthService là nguồn chính cho sức khỏe.
      steps: HealthService.data.steps,
      workoutMinutes: HealthService.data.activeMinutes,
      water: HealthService.data.water,

      // Nếu Health chưa có BMI hợp lệ thì giữ BMI đang có trên Supabase.
      bmi: HealthService.data.bmi > 0
          ? HealthService.data.bmi
          : (current?.bmi ?? 0),
    );

    await saveRecord(record);
  }

  static Future<void> seedDemoLast7Days() async {
    final now = DateTime.now();

    final demoData = [
      {
        'caloriesIntake': 2100,
        'caloriesBurned': 280,
        'steps': 5200,
        'workoutMinutes': 25,
        'completedExercises': 3,
        'water': 1.5,
        'bmi': 21.7,
      },
      {
        'caloriesIntake': 1950,
        'caloriesBurned': 350,
        'steps': 6800,
        'workoutMinutes': 35,
        'completedExercises': 4,
        'water': 1.8,
        'bmi': 21.7,
      },
      {
        'caloriesIntake': 2300,
        'caloriesBurned': 150,
        'steps': 3500,
        'workoutMinutes': 15,
        'completedExercises': 2,
        'water': 1.2,
        'bmi': 21.7,
      },
      {
        'caloriesIntake': 1850,
        'caloriesBurned': 500,
        'steps': 10500,
        'workoutMinutes': 60,
        'completedExercises': 6,
        'water': 2.3,
        'bmi': 21.7,
      },
      {
        'caloriesIntake': 2000,
        'caloriesBurned': 420,
        'steps': 8900,
        'workoutMinutes': 50,
        'completedExercises': 5,
        'water': 2.0,
        'bmi': 21.7,
      },
      {
        'caloriesIntake': 1750,
        'caloriesBurned': 240,
        'steps': 6100,
        'workoutMinutes': 30,
        'completedExercises': 3,
        'water': 1.7,
        'bmi': 21.7,
      },
      {
        'caloriesIntake': 2050,
        'caloriesBurned': 380,
        'steps': 7600,
        'workoutMinutes': 45,
        'completedExercises': 4,
        'water': 2.1,
        'bmi': 21.7,
      },
    ];

    for (int i = 0; i < 7; i++) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - i));

      final data = demoData[i];

      _records[dateKey(date)] = DailyRecord(
        date: date,
        caloriesIntake: data['caloriesIntake'] as int,
        caloriesBurned: data['caloriesBurned'] as int,
        steps: data['steps'] as int,
        workoutMinutes: data['workoutMinutes'] as int,
        completedExercises: data['completedExercises'] as int,
        water: data['water'] as double,
        bmi: data['bmi'] as double,
      );
    }

    await _saveData();

    notifier.value++;
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutService {
  WorkoutService._();

  static const String _completedKey = 'workout_completed_today';
  static const String _dateKey = 'workout_progress_date';
  static const String _caloriesBurnedKey = 'workout_calories_burned_today';

  static String _userKey(String key, String userId) {
    return '${key}_$userId';
  }

  // Full Body Workout hiện có 6 bài
  static const int dailyWorkoutGoal = 6;

  static int _completedToday = 0;
  static int _caloriesBurnedToday = 0;

  static int get caloriesBurnedToday => _caloriesBurnedToday;

  static int get completedToday => _completedToday;

  static String? _loadedDate;

  static String? get loadedDate => _loadedDate;

  static bool get isNewDay {
    return _loadedDate != null && _loadedDate != _todayKey();
  }

  static Future<void> ensureCurrentDay() async {
    if (_loadedDate == _todayKey()) return;

    await startNewDay();
  }

  static double get progress {
    if (dailyWorkoutGoal == 0) return 0;

    return (_completedToday / dailyWorkoutGoal).clamp(0.0, 1.0);
  }

  static int get progressPercent {
    return (progress * 100).round();
  }

  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);

  static Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final user = Supabase.instance.client.auth.currentUser;

    // Chưa đăng nhập thì không dùng dữ liệu của tài khoản cũ.
    if (user == null) {
      _completedToday = 0;
      _caloriesBurnedToday = 0;
      _loadedDate = _todayKey();

      notifyChanges();
      return;
    }

    final userId = user.id;

    // 1. Đọc cache local của đúng tài khoản.
    _completedToday = prefs.getInt(_userKey(_completedKey, userId)) ?? 0;

    _caloriesBurnedToday =
        prefs.getInt(_userKey(_caloriesBurnedKey, userId)) ?? 0;

    _loadedDate = prefs.getString(_userKey(_dateKey, userId));

    // 2. Lấy dữ liệu hôm nay từ Supabase.
    try {
      final response = await Supabase.instance.client
          .from('daily_records')
          .select('completed_exercises, calories_burned')
          .eq('user_id', userId)
          .eq('record_date', _todayKey())
          .maybeSingle();

      if (response != null) {
        _completedToday =
            (response['completed_exercises'] as num?)?.toInt() ?? 0;

        _caloriesBurnedToday =
            (response['calories_burned'] as num?)?.toInt() ?? 0;
      } else {
        _completedToday = 0;
        _caloriesBurnedToday = 0;
      }

      _loadedDate = _todayKey();

      // Đồng bộ cloud xuống cache của đúng tài khoản.
      await prefs.setInt(_userKey(_completedKey, userId), _completedToday);

      await prefs.setInt(
        _userKey(_caloriesBurnedKey, userId),
        _caloriesBurnedToday,
      );

      await prefs.setString(_userKey(_dateKey, userId), _todayKey());
    } catch (e) {
      debugPrint('WorkoutService Supabase load error: $e');

      _loadedDate ??= _todayKey();
    }

    notifyChanges();
  }

  static Future<void> completeWorkout({required int caloriesBurned}) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập.');
    }

    // Nếu app đang giữ dữ liệu của ngày cũ thì reset trước.
    if (_loadedDate != _todayKey()) {
      _completedToday = 0;
      _caloriesBurnedToday = 0;
    }

    if (_completedToday < dailyWorkoutGoal) {
      _completedToday++;
    }

    _caloriesBurnedToday += caloriesBurned;
    _loadedDate = _todayKey();

    final prefs = await SharedPreferences.getInstance();

    // 1. Lưu cache local theo đúng tài khoản.
    await prefs.setInt(_userKey(_completedKey, user.id), _completedToday);

    await prefs.setInt(
      _userKey(_caloriesBurnedKey, user.id),
      _caloriesBurnedToday,
    );

    await prefs.setString(_userKey(_dateKey, user.id), _todayKey());

    // 2. Đồng bộ kết quả workout lên daily_records.
    await Supabase.instance.client.from('daily_records').upsert({
      'user_id': user.id,
      'record_date': _todayKey(),
      'completed_exercises': _completedToday,
      'calories_burned': _caloriesBurnedToday,
    }, onConflict: 'user_id,record_date');

    notifyChanges();
  }

  static Future<void> resetToday() async {
    final user = Supabase.instance.client.auth.currentUser;

    _completedToday = 0;
    _caloriesBurnedToday = 0;
    _loadedDate = _todayKey();

    if (user != null) {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt(_userKey(_completedKey, user.id), 0);

      await prefs.setInt(_userKey(_caloriesBurnedKey, user.id), 0);

      await prefs.setString(_userKey(_dateKey, user.id), _todayKey());
    }

    notifyChanges();
  }

  static Future<void> startNewDay() async {
    if (_loadedDate == _todayKey()) return;

    await loadData();

    if (_loadedDate == _todayKey()) return;

    await resetToday();
  }

  static String _todayKey() {
    final now = DateTime.now();

    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  static void notifyChanges() {
    notifier.value++;
  }
}

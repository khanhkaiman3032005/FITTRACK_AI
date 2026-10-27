import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/meal_entry.dart';
import '../models/food_data.dart';
import 'daily_history_service.dart';

class NutritionService {
  NutritionService._();

  static const String _storageKey = 'nutrition_entries';

  static String _storageKeyForUser(String userId) {
    return '${_storageKey}_$userId';
  }

  static final List<MealEntry> _entries = [];

  // Dùng để các màn hình tự động rebuild khi dinh dưỡng thay đổi.
  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);

  static List<MealEntry> get entries => List<MealEntry>.unmodifiable(_entries);

  static List<MealEntry> get todayEntries {
    final now = DateTime.now();

    return List<MealEntry>.unmodifiable(
      _entries.where(
        (item) =>
            item.createdAt.year == now.year &&
            item.createdAt.month == now.month &&
            item.createdAt.day == now.day,
      ),
    );
  }

  static Map<String, dynamic> _toSupabase({
    required String userId,
    required MealEntry entry,
  }) {
    return {
      'user_id': userId,
      'meal_date':
          '${entry.createdAt.year.toString().padLeft(4, '0')}-'
          '${entry.createdAt.month.toString().padLeft(2, '0')}-'
          '${entry.createdAt.day.toString().padLeft(2, '0')}',
      'meal_type': entry.mealType,
      'food_name': entry.food.name,
      'food_category': entry.food.category,
      'food_unit': entry.food.unit,
      'quantity': entry.quantity,
      'calories': entry.food.calories,
      'protein': entry.food.protein,
      'carbs': entry.food.carbs,
      'fat': entry.food.fat,
      'created_at': entry.createdAt.toIso8601String(),
    };
  }

  static MealEntry _fromSupabase(Map<String, dynamic> row) {
    return MealEntry(
      id: (row['id'] as num?)?.toInt(),
      food: FoodData(
        name: row['food_name'] as String? ?? '',
        category: row['food_category'] as String? ?? '',
        calories: (row['calories'] as num?)?.toInt() ?? 0,
        protein: (row['protein'] as num?)?.toDouble() ?? 0,
        carbs: (row['carbs'] as num?)?.toDouble() ?? 0,
        fat: (row['fat'] as num?)?.toDouble() ?? 0,
        unit: row['food_unit'] as String? ?? '',
      ),
      mealType: row['meal_type'] as String? ?? '',
      quantity: (row['quantity'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  // =========================
  // LOAD DATA
  // =========================

  static Future<void> loadData() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      _entries.clear();
      notifier.value++;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final localKey = _storageKeyForUser(user.id);

    try {
      // Supabase là nguồn dữ liệu chính.
      final response = await Supabase.instance.client
          .from('meal_entries')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: true);

      final rows = List<Map<String, dynamic>>.from(response);

      _entries
        ..clear()
        ..addAll(rows.map(_fromSupabase));

      // Cache local riêng cho đúng tài khoản.
      await prefs.setString(
        localKey,
        jsonEncode(_entries.map((entry) => entry.toJson()).toList()),
      );

      notifier.value++;
    } catch (e) {
      debugPrint('NutritionService.loadData Supabase error: $e');

      // Mất mạng thì mới fallback về cache của tài khoản này.
      final savedData = prefs.getString(localKey);

      _entries.clear();

      if (savedData != null && savedData.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(savedData);

        _entries.addAll(
          decoded.map(
            (item) => MealEntry.fromJson(Map<String, dynamic>.from(item)),
          ),
        );
      }

      notifier.value++;
    }
  }

  // =========================
  // SAVE DATA
  // =========================

  static Future<void> _saveData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();

      final encoded = jsonEncode(
        _entries.map((entry) => entry.toJson()).toList(),
      );

      await prefs.setString(_storageKeyForUser(user.id), encoded);
    } catch (e) {
      debugPrint('Lỗi save NutritionData: $e');
    }
  }

  // =========================
  // ADD
  // =========================

  static Future<void> addMeal(MealEntry entry) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập.');
    }

    // 1. Insert vào Supabase và lấy record vừa tạo.
    final response = await Supabase.instance.client
        .from('meal_entries')
        .insert(_toSupabase(userId: user.id, entry: entry))
        .select()
        .single();

    // 2. Chuyển record Supabase thành MealEntry có ID.
    final savedEntry = _fromSupabase(Map<String, dynamic>.from(response));

    // 3. Chỉ thêm record đã có ID vào local.
    _entries.add(savedEntry);

    await _saveData();

    notifier.value++;

    await DailyHistoryService.saveTodaySnapshot();
  }

  // =========================
  // REMOVE
  // =========================

  static Future<void> removeMeal(MealEntry entry) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập.');
    }

    if (entry.id == null) {
      throw Exception('Không tìm thấy ID của món ăn.');
    }

    // 1. Xóa đúng record của đúng tài khoản trên Supabase.
    await Supabase.instance.client
        .from('meal_entries')
        .delete()
        .eq('id', entry.id!)
        .eq('user_id', user.id);

    // 2. Supabase xóa thành công mới xóa local.
    _entries.remove(entry);

    await _saveData();

    notifier.value++;

    await DailyHistoryService.saveTodaySnapshot();
  }

  // =========================
  // CLEAR
  // =========================
  static Future<void> clear() async {
    _entries.clear();

    await _saveData();

    notifier.value++;

    await DailyHistoryService.saveTodaySnapshot();
  }

  // =========================
  // TOTALS
  // =========================

  static int get totalCalories {
    final now = DateTime.now();
    return totalCaloriesForDate(now);
  }

  static int totalCaloriesForDate(DateTime date) {
    return _entries
        .where(
          (item) =>
              item.createdAt.year == date.year &&
              item.createdAt.month == date.month &&
              item.createdAt.day == date.day,
        )
        .fold(0, (sum, item) => sum + item.totalCalories);
  }

  static double get totalProtein {
    final now = DateTime.now();

    return _entries
        .where(
          (item) =>
              item.createdAt.year == now.year &&
              item.createdAt.month == now.month &&
              item.createdAt.day == now.day,
        )
        .fold(0.0, (sum, item) => sum + item.totalProtein);
  }

  static double get totalCarbs {
    final now = DateTime.now();

    return _entries
        .where(
          (item) =>
              item.createdAt.year == now.year &&
              item.createdAt.month == now.month &&
              item.createdAt.day == now.day,
        )
        .fold(0.0, (sum, item) => sum + item.totalCarbs);
  }

  static double get totalFat {
    final now = DateTime.now();

    return _entries
        .where(
          (item) =>
              item.createdAt.year == now.year &&
              item.createdAt.month == now.month &&
              item.createdAt.day == now.day,
        )
        .fold(0.0, (sum, item) => sum + item.totalFat);
  }
}

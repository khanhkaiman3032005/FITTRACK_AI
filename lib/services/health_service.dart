import 'profile_service.dart';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/health_data.dart';
import 'daily_history_service.dart';

class HealthService {
  HealthService._();

  static const String _heightKey = 'health_height';
  static const String _weightKey = 'health_weight';
  static const String _heartRateKey = 'health_heart_rate';
  static const String _sleepHoursKey = 'health_sleep_hours';

  static const String _stepsKey = 'health_steps';
  static const String _waterKey = 'health_water';
  static const String _activeMinutesKey = 'health_active_minutes';
  static const String _dateKey = 'health_progress_date';

  static String? _loadedDate;

  static String? get loadedDate => _loadedDate;

  static String _userKey(String key, String userId) {
    return '${key}_$userId';
  }

  static bool get isNewDay {
    return _loadedDate != null && _loadedDate != _todayKey();
  }

  static Future<void> ensureCurrentDay() async {
    if (_loadedDate == _todayKey()) return;

    await startNewDay();
  }

  static HealthData _data = const HealthData(
    height: 0,
    weight: 0,
    heartRate: 0,
    sleepHours: 0,
    steps: 0,
    water: 0.0,
    activeMinutes: 0,
  );

  static HealthData get data => _data;

  // Đọc dữ liệu đã lưu khi mở ứng dụng
  static Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final user = Supabase.instance.client.auth.currentUser;

    // Chưa đăng nhập
    if (user == null) {
      _data = const HealthData(
        height: 0,
        weight: 0,
        heartRate: 0,
        sleepHours: 0,
        steps: 0,
        water: 0.0,
        activeMinutes: 0,
      );

      _loadedDate = _todayKey();
      notifyChanges();
      return;
    }

    final userId = user.id;

    // =========================================================
    // 1. Đọc cache local RIÊNG của tài khoản hiện tại
    // =========================================================

    _data = HealthData(
      height: prefs.getDouble(_userKey(_heightKey, userId)) ?? 0,
      weight: prefs.getDouble(_userKey(_weightKey, userId)) ?? 0,
      heartRate: prefs.getInt(_userKey(_heartRateKey, userId)) ?? 0,
      sleepHours: prefs.getDouble(_userKey(_sleepHoursKey, userId)) ?? 0,
      steps: prefs.getInt(_userKey(_stepsKey, userId)) ?? 0,
      water: prefs.getDouble(_userKey(_waterKey, userId)) ?? 0.0,
      activeMinutes: prefs.getInt(_userKey(_activeMinutesKey, userId)) ?? 0,
    );

    _loadedDate = prefs.getString(_userKey(_dateKey, userId));

    // =========================================================
    // 2. Lấy profile từ Supabase
    // =========================================================

    try {
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('height, weight, heart_rate, sleep_hours')
          .eq('id', userId)
          .maybeSingle();

      if (profileResponse != null) {
        // Có hồ sơ trên Supabase -> lấy chiều cao/cân nặng của tài khoản này.
        _data = HealthData(
          height: (profileResponse['height'] as num?)?.toDouble() ?? 0,
          weight: (profileResponse['weight'] as num?)?.toDouble() ?? 0,
          heartRate:
              (profileResponse['heart_rate'] as num?)?.toInt() ??
              _data.heartRate,
          sleepHours:
              (profileResponse['sleep_hours'] as num?)?.toDouble() ??
              _data.sleepHours,
          steps: _data.steps,
          water: _data.water,
          activeMinutes: _data.activeMinutes,
        );
      } else {
        // Không có profile trên Supabase -> tài khoản chưa cập nhật hồ sơ.
        // Không được giữ height/weight cũ trong SharedPreferences.
        _data = HealthData(
          height: 0,
          weight: 0,
          heartRate: _data.heartRate,
          sleepHours: _data.sleepHours,
          steps: _data.steps,
          water: _data.water,
          activeMinutes: _data.activeMinutes,
        );

        // Xóa cache chỉ số cơ thể cũ của đúng tài khoản này.
        await prefs.remove(_userKey(_heightKey, userId));
        await prefs.remove(_userKey(_weightKey, userId));
      }
    } catch (e) {
      debugPrint('HealthService profile load error: $e');
    }

    // =========================================================
    // 3. Lấy tiến độ HÔM NAY từ Supabase
    // =========================================================

    try {
      final dailyResponse = await Supabase.instance.client
          .from('daily_records')
          .select('steps, water, workout_minutes')
          .eq('user_id', userId)
          .eq('record_date', _todayKey())
          .maybeSingle();

      if (dailyResponse != null) {
        _data = HealthData(
          height: _data.height,
          weight: _data.weight,
          heartRate: _data.heartRate,
          sleepHours: _data.sleepHours,
          steps: (dailyResponse['steps'] as num?)?.toInt() ?? 0,
          water: (dailyResponse['water'] as num?)?.toDouble() ?? 0.0,
          activeMinutes:
              (dailyResponse['workout_minutes'] as num?)?.toInt() ?? 0,
        );
      } else {
        // Tài khoản này chưa có dữ liệu hôm nay.
        _data = HealthData(
          height: _data.height,
          weight: _data.weight,
          heartRate: _data.heartRate,
          sleepHours: _data.sleepHours,
          steps: 0,
          water: 0.0,
          activeMinutes: 0,
        );
      }

      _loadedDate = _todayKey();

      // Đồng bộ dữ liệu cloud vừa lấy về cache local.
      await _saveData();
    } catch (e) {
      debugPrint('HealthService daily_records load error: $e');

      // Mất mạng thì vẫn dùng cache local của đúng tài khoản.
      _loadedDate ??= _todayKey();
    }

    notifyChanges();
  }

  // Lưu toàn bộ dữ liệu xuống máy
  static Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) return;

    final userId = user.id;

    await prefs.setDouble(_userKey(_heightKey, userId), _data.height);

    await prefs.setDouble(_userKey(_weightKey, userId), _data.weight);

    await prefs.setInt(_userKey(_heartRateKey, userId), _data.heartRate);

    await prefs.setDouble(_userKey(_sleepHoursKey, userId), _data.sleepHours);

    await prefs.setInt(_userKey(_stepsKey, userId), _data.steps);

    await prefs.setDouble(_userKey(_waterKey, userId), _data.water);

    await prefs.setInt(
      _userKey(_activeMinutesKey, userId),
      _data.activeMinutes,
    );

    await prefs.setString(_userKey(_dateKey, userId), _todayKey());

    _loadedDate = _todayKey();
  }

  // Cập nhật chỉ số cơ thể

  static Future<void> updateHealth({
    required double height,
    required double weight,
    required int heartRate,
    required double sleepHours,
  }) async {
    await ensureCurrentDay();
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập.');
    }

    final updated = await Supabase.instance.client
        .from('profiles')
        .update({
          'height': height,
          'weight': weight,
          'heart_rate': heartRate,
          'sleep_hours': sleepHours,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id)
        .select('id')
        .maybeSingle();

    if (updated == null) {
      throw Exception('Không tìm thấy hồ sơ để cập nhật.');
    }

    _data = HealthData(
      height: height,
      weight: weight,
      heartRate: heartRate,
      sleepHours: sleepHours,
      steps: _data.steps,
      water: _data.water,
      activeMinutes: _data.activeMinutes,
    );

    await _saveData();
    notifyChanges();

    await ProfileService.loadData();
  }

  // Cập nhật tiến độ hôm nay
  static Future<void> updateProgress({
    int? steps,
    double? water,
    int? activeMinutes,
  }) async {
    await ensureCurrentDay();
    _data = HealthData(
      height: _data.height,
      weight: _data.weight,
      heartRate: _data.heartRate,
      sleepHours: _data.sleepHours,
      steps: steps ?? _data.steps,
      water: water ?? _data.water,
      activeMinutes: activeMinutes ?? _data.activeMinutes,
    );

    // 1. Lưu cache local của tài khoản hiện tại.
    await _saveData();

    // 2. Đồng bộ tiến độ hôm nay lên Supabase.
    try {
      await DailyHistoryService.saveTodaySnapshot();
    } catch (e) {
      debugPrint('HealthService sync daily_records error: $e');
    }

    // 3. Báo cho UI cập nhật.
    notifyChanges();
  }

  static Future<void> startNewDay() async {
    if (_loadedDate == _todayKey()) return;

    await loadData();

    if (_loadedDate == _todayKey()) return;

    _data = HealthData(
      height: _data.height,
      weight: _data.weight,
      heartRate: _data.heartRate,
      sleepHours: _data.sleepHours,
      steps: 0,
      water: 0.0,
      activeMinutes: 0,
    );

    _loadedDate = _todayKey();

    await _saveData();
    notifyChanges();
  }

  static String _todayKey() {
    final now = DateTime.now();

    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);

  static void notifyChanges() {
    notifier.value++;
  }
}

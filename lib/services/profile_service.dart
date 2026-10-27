import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

class ProfileService {
  static String _profileKeyForUser(String userId) {
    return 'user_profile_$userId';
  }

  static final ValueNotifier<UserProfile> notifier = ValueNotifier<UserProfile>(
    _defaultProfile,
  );

  static UserProfile get profile => notifier.value;

  static const UserProfile _defaultProfile = UserProfile(
    name: 'Người dùng FITTRACK',
    age: 0,
    gender: 'Nam',
    height: 0,
    weight: 0,
    targetWeight: 0,
    dailyStepGoal: 10000,
    dailyWaterGoal: 2.0,
    dailyCalorieGoal: 2000,
    dailyActiveMinutesGoal: 30,
  );

  static Future<void> loadData() async {
    final user = Supabase.instance.client.auth.currentUser;

    // Chưa đăng nhập thì dùng profile mặc định.
    if (user == null) {
      notifier.value = _defaultProfile;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final localKey = _profileKeyForUser(user.id);

    // Không dùng profile local làm nguồn chính.
    // Profile thật của tài khoản sẽ lấy từ Supabase.
    UserProfile localProfile = _defaultProfile;

    try {
      // 2. Tìm profile của user đang đăng nhập trên Supabase.
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        // Đã có trên Supabase -> Supabase là nguồn dữ liệu chính.
        final profile = _fromSupabase(data);

        notifier.value = profile;

        // Cache lại local.
        await prefs.setString(localKey, jsonEncode(profile.toJson()));

        return;
      }

      // 3. Supabase chưa có profile.
      // Đây là tài khoản chưa cập nhật hồ sơ.
      notifier.value = _defaultProfile;

      // Xóa cache cũ của chính tài khoản này để không còn
      // height/weight/BMI từ dữ liệu trước đây.
      await prefs.remove(localKey);
    } catch (e) {
      // Nếu mất mạng/Supabase lỗi thì vẫn dùng cache local.
      notifier.value = localProfile;
      debugPrint('ProfileService.loadData Supabase error: $e');
    }
  }

  static Future<void> saveProfile(UserProfile profile) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập.');
    }

    // Lưu Supabase trước.
    await Supabase.instance.client
        .from('profiles')
        .upsert(
          _toSupabase(userId: user.id, profile: profile),
          onConflict: 'id',
        );

    // Supabase thành công mới cập nhật state/cache.
    notifier.value = profile;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _profileKeyForUser(user.id),
      jsonEncode(profile.toJson()),
    );
  }

  static Future<void> resetProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    final prefs = await SharedPreferences.getInstance();

    if (user != null) {
      await Supabase.instance.client
          .from('profiles')
          .delete()
          .eq('id', user.id);

      await prefs.remove(_profileKeyForUser(user.id));
    }

    notifier.value = _defaultProfile;
  }

  static Map<String, dynamic> _toSupabase({
    required String userId,
    required UserProfile profile,
  }) {
    return {
      'id': userId,
      'name': profile.name,
      'age': profile.age,
      'gender': profile.gender,
      'height': profile.height,
      'weight': profile.weight,
      'target_weight': profile.targetWeight,
      'daily_step_goal': profile.dailyStepGoal,
      'daily_water_goal': profile.dailyWaterGoal,
      'daily_calorie_goal': profile.dailyCalorieGoal,
      'daily_active_minutes_goal': profile.dailyActiveMinutesGoal,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  static UserProfile _fromSupabase(Map<String, dynamic> data) {
    return UserProfile(
      name: data['name'] as String? ?? 'Người dùng FITTRACK',
      age: (data['age'] as num?)?.toInt() ?? 0,
      gender: data['gender'] as String? ?? 'Nam',
      height: (data['height'] as num?)?.toDouble() ?? 0,
      weight: (data['weight'] as num?)?.toDouble() ?? 0,
      targetWeight: (data['target_weight'] as num?)?.toDouble() ?? 0,
      dailyStepGoal: (data['daily_step_goal'] as num?)?.toInt() ?? 10000,
      dailyWaterGoal: (data['daily_water_goal'] as num?)?.toDouble() ?? 2.0,
      dailyCalorieGoal: (data['daily_calorie_goal'] as num?)?.toInt() ?? 2000,
      dailyActiveMinutesGoal:
          (data['daily_active_minutes_goal'] as num?)?.toInt() ?? 30,
    );
  }
}

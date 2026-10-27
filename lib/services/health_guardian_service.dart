import 'package:supabase_flutter/supabase_flutter.dart';

class GuardianHealthProfile {
  final bool hasCondition;
  final List<String> conditionTypes;
  final String notes;
  const GuardianHealthProfile({
    required this.hasCondition,
    required this.conditionTypes,
    required this.notes,
  });
  factory GuardianHealthProfile.fromJson(Map<String, dynamic> json) =>
      GuardianHealthProfile(
        hasCondition: json['has_health_condition'] == true,
        conditionTypes: List<String>.from(json['condition_types'] ?? const []),
        notes: (json['condition_notes'] as String?) ?? '',
      );
}

class HealthGuardianService {
  HealthGuardianService._();
  static SupabaseClient get _db => Supabase.instance.client;
  static String get _uid {
    final user = _db.auth.currentUser;
    if (user == null) throw StateError('Vui lòng đăng nhập.');
    return user.id;
  }

  static Future<GuardianHealthProfile?> loadProfile() async {
    final row = await _db
        .from('health_guardian_profiles')
        .select('has_health_condition,condition_types,condition_notes')
        .eq('user_id', _uid)
        .maybeSingle();
    return row == null ? null : GuardianHealthProfile.fromJson(row);
  }

  static Future<void> saveProfile(GuardianHealthProfile profile) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _db.from('health_guardian_profiles').upsert({
      'user_id': _uid,
      'has_health_condition': profile.hasCondition,
      'condition_types': profile.hasCondition
          ? profile.conditionTypes
          : <String>[],
      'condition_notes': profile.hasCondition ? profile.notes.trim() : '',
      'screening_version': 2,
      'consent_at': now,
      'updated_at': now,
    }, onConflict: 'user_id');
    clearApproval();
  }

  static Future<bool> hasRecentVeryHighEffort() async {
    final since = DateTime.now()
        .toUtc()
        .subtract(const Duration(hours: 24))
        .toIso8601String();
    final rows = await _db
        .from('workout_health_checks')
        .select('rpe,status')
        .eq('user_id', _uid)
        .eq('phase', 'after')
        .gte('created_at', since)
        .order('created_at', ascending: false)
        .limit(50);
    return rows.any(
      (r) =>
          ((r['rpe'] as num?)?.toInt() ?? 0) >= 9 ||
          r['status'] == 'high_effort',
    );
  }

  // Giữ tương thích màn hình PostWorkoutCheckScreen từ bản 1.0.
  static Future<void> saveCheck({
    required String exerciseName,
    required String phase,
    required String status,
    bool hasSymptoms = false,
    bool isTired = false,
    int? rpe,
    String? decisionCode,
  }) async {
    await _db.from('workout_health_checks').insert({
      'user_id': _uid,
      'exercise_name': exerciseName,
      'phase': phase,
      'status': status,
      'has_symptoms': hasSymptoms,
      'is_tired': isTired,
      'rpe': rpe,
      'decision_code':
          decisionCode ??
          (hasSymptoms
              ? (phase == 'after' ? 'SYMPTOMS_AFTER' : 'USER_REPORTED_SYMPTOMS')
              : (phase == 'after' && status == 'high_effort'
                    ? 'HIGH_RPE'
                    : (phase == 'after' && status == 'completed'
                          ? 'NO_REPORTED_FLAG'
                          : null))),
    });
  }

  // Chỉ kiểm soát điều hướng trong UI; không phải xác thực y tế.
  static String? _approvedUser;
  static String? _approvedExercise;
  static DateTime? _deadline;
  static void approveForOnce(String exerciseName) {
    _approvedUser = _uid;
    _approvedExercise = exerciseName;
    _deadline = DateTime.now().add(const Duration(minutes: 5));
  }

  static bool consumeApproval(String exerciseName) {
    final allowed =
        _approvedUser == _uid &&
        _approvedExercise == exerciseName &&
        _deadline != null &&
        DateTime.now().isBefore(_deadline!);
    clearApproval();
    return allowed;
  }

  static void clearApproval() {
    _approvedUser = null;
    _approvedExercise = null;
    _deadline = null;
  }
}

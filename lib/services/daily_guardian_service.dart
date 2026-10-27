import 'package:supabase_flutter/supabase_flutter.dart';

import 'exercise_safety_engine.dart';
import 'health_guardian_service.dart';

class DailyGuardianRecord {
  final DateTime day;
  final bool symptoms;
  final bool tired;
  final String decisionCode;
  final bool hasCondition;
  // Flags remembering if a warning was ever reported today.
  final bool hadSymptomsToday;
  final bool hadTiredToday;

  const DailyGuardianRecord({
    required this.day,
    required this.symptoms,
    required this.tired,
    required this.decisionCode,
    required this.hasCondition,
    required this.hadSymptomsToday,
    required this.hadTiredToday,
  });

  factory DailyGuardianRecord.fromMap(Map<String, dynamic> data) =>
      DailyGuardianRecord(
        day: DateTime.parse(data['check_date'] as String),
        symptoms: data['current_symptoms'] == true,
        tired: data['current_tired'] == true,
        decisionCode: data['decision_code'] as String? ?? '',
        hasCondition: data['has_condition_snapshot'] == true,
        hadSymptomsToday: data['has_symptoms'] == true,
        hadTiredToday: data['is_tired'] == true,
      );
}

class DailyGuardianState {
  final DailyGuardianRecord? record;
  final GuardianDecision? decision;
  final bool hadWarningToday;

  const DailyGuardianState({
    required this.record,
    required this.decision,
    required this.hadWarningToday,
  });

  bool get needsForm => record == null;
  bool get canStart => record != null && decision?.canStart == true;
}

class DailyGuardianService {
  DailyGuardianService._();

  static SupabaseClient get _db => Supabase.instance.client;
  static String get _uid {
    final user = _db.auth.currentUser;
    if (user == null) throw StateError('Bạn cần đăng nhập để luyện tập.');
    return user.id;
  }

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime get _localStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static Future<DailyGuardianRecord?> loadToday() async {
    final row = await _db
        .from('daily_guardian_checks')
        .select(
          'check_date,has_symptoms,is_tired,current_symptoms,current_tired,decision_code,has_condition_snapshot',
        )
        .eq('user_id', _uid)
        .eq('check_date', dayKey(DateTime.now()))
        .maybeSingle();
    return row == null ? null : DailyGuardianRecord.fromMap(row);
  }

  static Future<bool> _warningToday() async {
    final start = _localStart.toUtc();
    final end = _localStart.add(const Duration(days: 1)).toUtc();
    final rows = await _db
        .from('workout_health_checks')
        .select('phase,has_symptoms')
        .eq('user_id', _uid)
        .gte('created_at', start.toIso8601String())
        .lt('created_at', end.toIso8601String())
        .eq('has_symptoms', true)
        .limit(1);
    return rows.isNotEmpty;
  }

  static Future<DailyGuardianState> evaluateToday() async {
    // No in-memory decision cache: profile changes and workout alerts take effect.
    final profile = await HealthGuardianService.loadProfile();
    final record = await loadToday();
    if (record == null) {
      return const DailyGuardianState(
        record: null,
        decision: null,
        hadWarningToday: false,
      );
    }
    final hadWarning = await _warningToday();
    final highRpe = await HealthGuardianService.hasRecentVeryHighEffort();
    final decision = ExerciseSafetyEngine.assess(
      hasProfile: profile != null,
      hasCondition: profile?.hasCondition == true,
      hasSymptoms: record.hadSymptomsToday || hadWarning,
      // Fatigue is self-reported and can improve during the day.
      veryTired: record.tired,
      recentVeryHighEffort: highRpe,
    );
    return DailyGuardianState(
      record: record,
      decision: decision,
      hadWarningToday: hadWarning,
    );
  }

  static Future<GuardianDecision> saveToday({
    required bool symptoms,
    required bool tired,
  }) async {
    final profile = await HealthGuardianService.loadProfile();
    if (profile == null) {
      throw StateError('Hãy hoàn thành hồ sơ sức khỏe lâu dài trước.');
    }
    // Preserve earlier symptom reports as an independent safety flag.
    // The editable answers are stored separately from historical flags.
    final old = await loadToday();
    final effectiveSymptoms =
        symptoms || (old?.hadSymptomsToday ?? false) || await _warningToday();
    final highRpe = await HealthGuardianService.hasRecentVeryHighEffort();
    final decision = ExerciseSafetyEngine.assess(
      hasProfile: true,
      hasCondition: profile.hasCondition,
      hasSymptoms: effectiveSymptoms,
      veryTired: tired,
      recentVeryHighEffort: highRpe,
    );
    final uid = _uid;
    await _db.from('daily_guardian_checks').upsert({
      'user_id': uid,
      'check_date': dayKey(DateTime.now()),
      'has_symptoms': effectiveSymptoms,
      'is_tired': tired || (old?.hadTiredToday ?? false),
      'current_symptoms': symptoms,
      'current_tired': tired,
      'has_condition_snapshot': profile.hasCondition,
      'decision_code': decision.code,
      'checked_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,check_date');
    return decision;
  }

  /// Check again immediately before a workout. Only grant the existing
  /// one-use in-memory authorization if all current conditions permit it.
  static Future<DailyGuardianState> authorizeExercise(
    String exerciseName,
  ) async {
    HealthGuardianService.clearApproval();
    final state = await evaluateToday();
    if (state.canStart) {
      HealthGuardianService.approveForOnce(exerciseName);
    }
    return state;
  }
}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'coach_checkin_engine.dart';
import 'daily_guardian_service.dart';
import 'workout_service.dart';

/// Once-a-day text is assembled locally, without calling Gemini.
/// Reads the previous LOCAL calendar day (not a rolling 24-hour window).
class CoachCheckInService {
  CoachCheckInService._();

  static Future<CoachCheckIn?> loadForCurrentUser() async {
    final db = Supabase.instance.client;
    final userId = db.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final now = DateTime.now();
      final yesterday = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 1));
      final day = DailyGuardianService.dayKey(yesterday);
      final start = yesterday.toUtc();
      final end = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day + 1,
      ).toUtc();

      final profile = await db
          .from('health_guardian_profiles')
          .select('has_health_condition')
          .eq('user_id', userId)
          .maybeSingle();
      final daily = await db
          .from('daily_guardian_checks')
          .select('has_symptoms,is_tired,decision_code')
          .eq('user_id', userId)
          .eq('check_date', day)
          .maybeSingle();
      final checks = await db
          .from('workout_health_checks')
          .select('phase,status,rpe,has_symptoms,decision_code')
          .eq('user_id', userId)
          .gte('created_at', start.toIso8601String())
          .lt('created_at', end.toIso8601String())
          .limit(200);
      final history = await db
          .from('daily_records')
          .select('completed_exercises')
          .eq('user_id', userId)
          .eq('record_date', day)
          .maybeSingle();

      if (db.auth.currentUser?.id != userId) return null;
      final warning =
          daily?['has_symptoms'] == true ||
          checks.any(
            (x) =>
                x['has_symptoms'] == true ||
                x['decision_code'] == 'SYMPTOMS' ||
                x['decision_code'] == 'USER_REPORTED_SYMPTOMS',
          );
      final highRpe = checks.any(
        (x) =>
            x['phase'] == 'after' &&
            (((x['rpe'] as num?)?.toInt() ?? 0) >= 9 ||
                x['status'] == 'high_effort'),
      );
      final completed = (history?['completed_exercises'] as num?)?.toInt() ?? 0;

      if (warning) {
        return const CoachCheckIn(
          CoachCheckInKind.safety,
          'Hôm nay bạn cảm thấy thế nào?',
          'Hôm qua bạn báo dấu hiệu sức khỏe bất thường. '
              'Bạn đã được đánh giá y tế phù hợp chưa? Đừng cố tập khi chưa rõ tình trạng. '
              'Nếu có dấu hiệu cấp cứu, gọi 115.',
        );
      }
      if (profile?['has_health_condition'] == true ||
          daily?['decision_code'] == 'MEDICAL_REVIEW') {
        return const CoachCheckIn(
          CoachCheckInKind.medicalReview,
          'Hỏi thăm sức khỏe hôm nay',
          'Hồ sơ của bạn có hạn chế sức khỏe ảnh hưởng vận động. '
              'Hôm nay bạn cảm thấy thế nào? Hãy tuân thủ hướng dẫn y tế; '
              'ứng dụng không tự xác nhận mức tập an toàn.',
        );
      }
      if (daily?['is_tired'] == true || daily?['decision_code'] == 'FATIGUE') {
        return const CoachCheckIn(
          CoachCheckInKind.recovery,
          'Bạn đã hồi phục hơn chưa?',
          'Hôm qua bạn khai báo mệt hoặc chưa hồi phục. '
              'Hôm nay bạn cảm thấy tốt hơn chưa? Nếu chưa ổn, ưu tiên nghỉ ngơi.',
        );
      }
      if (highRpe) {
        return const CoachCheckIn(
          CoachCheckInKind.recovery,
          'Hôm nay bạn hồi phục thế nào?',
          'Hôm qua bạn ghi nhận RPE rất cao (9/10 trở lên). '
              'Hôm nay bạn cảm thấy ra sao? Đừng vội tăng cường độ.',
        );
      }
      if (completed > 0 &&
          WorkoutService.dailyWorkoutGoal > 0 &&
          completed >= WorkoutService.dailyWorkoutGoal) {
        return const CoachCheckIn(
          CoachCheckInKind.completed,
          'Hôm qua bạn đã hoàn thành mục tiêu!',
          'Bạn đã hoàn thành mục tiêu vận động hôm qua. '
              'Rất tốt! Hôm nay bạn thấy cơ thể hồi phục thế nào?',
        );
      }
      if (completed > 0) {
        return const CoachCheckIn(
          CoachCheckInKind.active,
          'Cảm nhận sau buổi tập hôm qua',
          'Hôm qua bạn đã có buổi tập. Hôm nay cơ thể bạn thấy thế nào? '
              'Hãy nghỉ khi cần thiết nhé.',
        );
      }
      return const CoachCheckIn(
        CoachCheckInKind.gentleCheckIn,
        'Chào ngày mới!',
        'Hôm qua mình chưa thấy buổi tập được ghi nhận. '
            'Hôm nay bạn cảm thấy thế nào? Nghỉ ngơi cũng quan trọng.',
      );
    } catch (e) {
      debugPrint('COACH DAILY CHECK-IN: Không đọc được dữ liệu: $e');
      return null; // Never make up a health claim on partial data.
    }
  }
}

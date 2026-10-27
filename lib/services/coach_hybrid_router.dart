import 'package:supabase_flutter/supabase_flutter.dart';

import 'trained_intent_classifier.dart';

import 'ai_coach_service.dart';
import 'daily_history_service.dart';
import 'health_service.dart';
import 'profile_service.dart';
import 'workout_service.dart';
import 'daily_guardian_service.dart';

/// Lightweight, deterministic routing. This is NOT a trained language model.
/// Unknown questions return null to trigger the existing Gemini fallback.
class CoachRouteResult {
  final String intent;
  final String answer;
  const CoachRouteResult(this.intent, this.answer);
}

class CoachHybridRouter {
  CoachHybridRouter._();

  static String normalize(String s) {
    var q = s.toLowerCase().trim();
    q = q.replaceAll('à', 'a');
    q = q.replaceAll('á', 'a');
    q = q.replaceAll('ạ', 'a');
    q = q.replaceAll('ả', 'a');
    q = q.replaceAll('ã', 'a');
    q = q.replaceAll('â', 'a');
    q = q.replaceAll('ầ', 'a');
    q = q.replaceAll('ấ', 'a');
    q = q.replaceAll('ậ', 'a');
    q = q.replaceAll('ẩ', 'a');
    q = q.replaceAll('ẫ', 'a');
    q = q.replaceAll('ă', 'a');
    q = q.replaceAll('ằ', 'a');
    q = q.replaceAll('ắ', 'a');
    q = q.replaceAll('ặ', 'a');
    q = q.replaceAll('ẳ', 'a');
    q = q.replaceAll('ẵ', 'a');
    q = q.replaceAll('è', 'e');
    q = q.replaceAll('é', 'e');
    q = q.replaceAll('ẹ', 'e');
    q = q.replaceAll('ẻ', 'e');
    q = q.replaceAll('ẽ', 'e');
    q = q.replaceAll('ê', 'e');
    q = q.replaceAll('ề', 'e');
    q = q.replaceAll('ế', 'e');
    q = q.replaceAll('ệ', 'e');
    q = q.replaceAll('ể', 'e');
    q = q.replaceAll('ễ', 'e');
    q = q.replaceAll('ì', 'i');
    q = q.replaceAll('í', 'i');
    q = q.replaceAll('ị', 'i');
    q = q.replaceAll('ỉ', 'i');
    q = q.replaceAll('ĩ', 'i');
    q = q.replaceAll('ò', 'o');
    q = q.replaceAll('ó', 'o');
    q = q.replaceAll('ọ', 'o');
    q = q.replaceAll('ỏ', 'o');
    q = q.replaceAll('õ', 'o');
    q = q.replaceAll('ô', 'o');
    q = q.replaceAll('ồ', 'o');
    q = q.replaceAll('ố', 'o');
    q = q.replaceAll('ộ', 'o');
    q = q.replaceAll('ổ', 'o');
    q = q.replaceAll('ỗ', 'o');
    q = q.replaceAll('ơ', 'o');
    q = q.replaceAll('ờ', 'o');
    q = q.replaceAll('ớ', 'o');
    q = q.replaceAll('ợ', 'o');
    q = q.replaceAll('ở', 'o');
    q = q.replaceAll('ỡ', 'o');
    q = q.replaceAll('ù', 'u');
    q = q.replaceAll('ú', 'u');
    q = q.replaceAll('ụ', 'u');
    q = q.replaceAll('ủ', 'u');
    q = q.replaceAll('ũ', 'u');
    q = q.replaceAll('ư', 'u');
    q = q.replaceAll('ừ', 'u');
    q = q.replaceAll('ứ', 'u');
    q = q.replaceAll('ự', 'u');
    q = q.replaceAll('ử', 'u');
    q = q.replaceAll('ữ', 'u');
    q = q.replaceAll('ỳ', 'y');
    q = q.replaceAll('ý', 'y');
    q = q.replaceAll('ỵ', 'y');
    q = q.replaceAll('ỷ', 'y');
    q = q.replaceAll('ỹ', 'y');
    q = q.replaceAll('đ', 'd');
    return q
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool has(String normalized, String phrase) =>
      (' $normalized ').contains(' ${normalize(phrase)} ');

  /// Order matters. Health warnings must precede generic workout keywords.
  static String? classify(String question) {
    final q = normalize(question);
    if (q.isEmpty) return null;

    if (_any(q, [
          'phiếu sức khỏe',
          'phiếu sức khoẻ',
          'phiếu sức khỏe hôm nay',
          'khai báo sức khỏe',
          'cập nhật sức khỏe hôm nay',
        ]) &&
        _any(q, [
          'đã',
          'chưa',
          'hôm nay',
          'cập nhật',
          'khai báo',
          'hoàn thành',
        ])) {
      return 'daily_health_check';
    }

    // App commands should never be confused with health metrics.
    if (_any(q, [
      'dong roi mo lai ai coach',
      'dong mo lai ai coach',
      'mo lai ai coach',
      'khoi dong lai ai coach',
    ])) {
      return 'app_usage';
    }

    // Explicit questions about why a workout is denied must take priority
    // over workout recommendations, regardless of exact wording.
    final asksWhy = _any(q, [
      'tai sao',
      'vi sao',
      'ly do',
      'sao lai',
      'sao toi',
    ]);
    final denied = _any(q, [
      'khong duoc',
      'khong the',
      'bi cam',
      'bi chan',
      'khong cho',
      'cam tap',
      'chan tap',
      'khong cho phep',
    ]);
    final workout = _any(q, [
      'tap',
      'luyen tap',
      'bai tap',
      'workout',
      'squat',
      'push up',
    ]);
    if ((asksWhy && denied && workout) ||
        _any(q, [
          'tai sao bi chan tap',
          'vi sao bi chan tap',
          'khong cho tap',
          'bi chan tap',
          'ly do chan tap',
        ])) {
      return 'safety_reason';
    }
    if (_any(q, [
      'đau ngực',
      'khó thở',
      'chóng mặt',
      'muốn ngất',
      'ngất',
      'tim đập bất thường',
      'cấp cứu',
    ])) {
      return 'symptoms';
    }
    if (_any(q, [
          'bệnh tim',
          'tim mạch',
          'hen suyễn',
          'cao huyết áp',
          'huyết áp cao',
          'chấn thương',
          'bệnh nền',
        ]) &&
        _any(q, [
          'tập',
          'luyện tập',
          'squat',
          'push up',
          'nên',
          'được không',
          'an toàn',
        ])) {
      return 'medical';
    }
    if (_any(q, [
      'vì sao bị chặn',
      'tại sao bị chặn',
      'không cho tập',
      'bị chặn tập',
      'lý do chặn',
    ])) {
      return 'safety_reason';
    }
    if (_any(q, ['quá sức', 'gắng sức', 'rpe', 'hồi phục', 'tập quá nhiều'])) {
      return 'recovery';
    }
    if (_any(q, [
      'hôm qua',
      'ngày hôm qua',
      'tuần này',
      '7 ngày',
      'bảy ngày',
      'mấy ngày',
      'tuần qua',
    ])) {
      return 'history';
    }
    if (_any(q, [
      'nên tập',
      'tập gì',
      'bài tập nào',
      'gợi ý tập',
      'gợi ý bài tập',
      'đề xuất bài tập',
      'luyện tập gì',
    ])) {
      return 'recommend';
    }
    if (_any(q, ['bmi', 'cân nặng', 'mục tiêu cân nặng', 'chiều cao'])) {
      return 'body';
    }
    if (_any(q, [
      'uống nước',
      'bao nhiêu nước',
      'nước uống',
      'đủ nước',
      'mấy lít nước',
    ])) {
      return 'water';
    }
    if (_any(q, [
      'bước chân',
      'bao nhiêu bước',
      'đi bộ',
      'đi được bao nhiêu',
    ])) {
      return 'steps';
    }
    if (_any(q, [
      'calo',
      'calories',
      'kcal',
      'dinh dưỡng',
      'ăn gì',
      'đã ăn',
      'bữa ăn',
      'protein',
      'thực phẩm',
    ])) {
      return 'nutrition';
    }
    if (_any(q, ['mục tiêu', 'tiến độ', 'hoàn thành chưa', 'còn thiếu'])) {
      return 'goals';
    }
    if (_any(q, [
      'hôm nay tôi tập',
      'tập hôm nay',
      'đã tập bao nhiêu',
      'bài đã tập',
      'số bài tập',
    ])) {
      return 'today_workout';
    }
    if (_any(q, [
      'tổng quan hôm nay',
      'phân tích hôm nay',
      'hôm nay thế nào',
      'tình hình hôm nay',
    ])) {
      return 'today';
    }
    return null;
  }

  static bool _any(String q, List<String> terms) => terms.any((t) => has(q, t));

  static Future<CoachRouteResult?> route(String question) async {
    final intent =
        classify(question) ?? await TrainedIntentClassifier.classify(question);
    if (intent == null) return null;
    switch (intent) {
      case 'daily_health_check':
        try {
          final record = await DailyGuardianService.loadToday();

          if (record == null) {
            return const CoachRouteResult(
              'daily_health_check',
              'Hôm nay bạn chưa có phiếu sức khỏe hằng ngày '
                  'được lưu trong FITTRACK AI. '
                  'Bạn có thể vào mục Luyện tập để hoàn thành phiếu.',
            );
          }

          final symptoms = record.symptoms ? 'Có' : 'Không';
          final tired = record.tired ? 'Có' : 'Không';

          final warning = record.hadSymptomsToday
              ? 'Hôm nay bạn từng khai báo triệu chứng bất thường. '
                    'Cảnh báo này vẫn được lưu dù tình trạng hiện tại đã thay đổi.'
              : record.hadTiredToday
              ? 'Hôm nay bạn từng khai báo mệt mỏi.'
              : 'Không ghi nhận cảnh báo triệu chứng hoặc mệt mỏi '
                    'trong phiếu hôm nay.';

          return CoachRouteResult(
            'daily_health_check',
            'Bạn đã cập nhật phiếu sức khỏe hôm nay.\n'
                'Tình trạng hiện tại:\n'
                '- Triệu chứng bất thường: $symptoms\n'
                '- Mệt mỏi: $tired\n\n'
                '$warning\n\n'
                'Kết quả này không xác nhận bạn đủ điều kiện '
                'y tế để luyện tập.',
          );
        } catch (_) {
          return const CoachRouteResult(
            'daily_health_check',
            'Mình chưa thể kiểm tra phiếu sức khỏe từ Supabase. '
                'Vui lòng thử lại sau. Không thể kết luận '
                'bạn chưa cập nhật phiếu.',
          );
        }
      case 'app_usage':
        return const CoachRouteResult(
          'app_usage',
          'Để kiểm tra lịch sử trò chuyện, bạn có thể quay về trang trước '
              'rồi mở AI Coach lại. Mình không tự đóng hoặc mở ứng dụng thay bạn. '
              'Lịch sử chat đã lưu sẽ được tải lại khi màn hình mở.',
        );
      case 'symptoms':
        return const CoachRouteResult(
          'symptoms',
          'Nếu bạn đang đau ngực, khó thở bất thường, choáng hoặc muốn ngất: hãy dừng vận động ngay. '
              'Nếu triệu chứng nghiêm trọng hoặc gợi ý cấp cứu, gọi 115 tại Việt Nam. '
              'FITTRACK không thể chẩn đoán hoặc xác nhận bạn đủ điều kiện tập.',
        );
      case 'medical':
        return const CoachRouteResult(
          'medical',
          'Với bệnh lý hoặc chấn thương có thể ảnh hưởng vận động, FITTRACK không tự xác định bài tập hay cường độ an toàn. '
              'Hãy được nhân viên y tế đánh giá và tuân theo giới hạn được hướng dẫn trước khi bắt đầu kế hoạch.',
        );
      case 'safety_reason':
        return CoachRouteResult(intent, await _safetyReason());
      case 'recovery':
        return CoachRouteResult(intent, await _recovery());
      case 'recommend':
        final reason = await _safetyBlockReason();
        if (reason != null) {
          return CoachRouteResult(
            intent,
            'Hiện chưa thể gợi ý bắt đầu bài tập: $reason. Bạn có thể cập nhật hồ sơ và phiếu sức khỏe trong mục Luyện tập.',
          );
        }
        return CoachRouteResult(intent, AiCoachService.suggestWorkout());
      case 'body':
        final p = ProfileService.profile;
        return CoachRouteResult(
          intent,
          'Chỉ số trong hồ sơ: cân nặng ${p.weight} kg, chiều cao ${p.height} cm; '
          'BMI hiện tại ${HealthService.data.bmi.toStringAsFixed(1)}. '
          'BMI chỉ là chỉ số tham khảo, không thay thế đánh giá sức khỏe.',
        );
      case 'water':
        final d = HealthService.data;
        final goal = ProfileService.profile.dailyWaterGoal;
        return CoachRouteResult(
          intent,
          'Hôm nay bạn đã ghi nhận ${d.water.toStringAsFixed(1)} L nước; mục tiêu đang đặt ${goal.toStringAsFixed(1)} L.',
        );
      case 'steps':
        final d = HealthService.data;
        final goal = ProfileService.profile.dailyStepGoal;
        return CoachRouteResult(
          intent,
          'Hôm nay bạn đã ghi nhận ${d.steps} bước trên mục tiêu $goal bước.',
        );
      case 'nutrition':
        return CoachRouteResult(intent, AiCoachService.suggestNutrition());
      case 'goals':
        return CoachRouteResult(intent, AiCoachService.analyzeToday());
      case 'today_workout':
        return CoachRouteResult(
          intent,
          'Hôm nay bạn đã hoàn thành ${WorkoutService.completedToday}/${WorkoutService.dailyWorkoutGoal} bài; '
          'năng lượng vận động ước tính ${WorkoutService.caloriesBurnedToday} kcal, '
          'thời gian vận động đã ghi nhận ${HealthService.data.activeMinutes} phút. '
          'Đây là số liệu tổng hợp, không phải danh sách chi tiết từng bài.',
        );
      case 'today':
        return CoachRouteResult(intent, AiCoachService.analyzeToday());
      case 'history':
        return CoachRouteResult(intent, _history(question));
      default:
        return null;
    }
  }

  static String _history(String question) {
    final recent = DailyHistoryService.getRecentRecords(days: 7);
    if (recent.isEmpty) {
      return 'Chưa có nhật ký trong 7 ngày gần đây. Mình không thể kết luận xu hướng khi thiếu dữ liệu.';
    }
    final q = normalize(question);
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final selected = has(q, 'hôm qua') || has(q, 'ngày hôm qua')
        ? recent
              .where(
                (r) =>
                    r.date.year == yesterday.year &&
                    r.date.month == yesterday.month &&
                    r.date.day == yesterday.day,
              )
              .toList()
        : recent;
    if (selected.isEmpty) {
      return 'Không tìm thấy bản ghi cho ngày hôm qua; không coi dữ liệu thiếu là 0.';
    }
    final b = StringBuffer(
      'Nhật ký ghi nhận ${selected.length} ngày có dữ liệu:\n',
    );
    for (final r in selected) {
      b.writeln(
        '${r.date.day}/${r.date.month}: ${r.completedExercises} bài, '
        'đốt ${r.caloriesBurned} kcal, nạp ${r.caloriesIntake} kcal, '
        '${r.workoutMinutes} phút vận động.',
      );
    }
    b.write(
      'Đây là dữ liệu đã lưu; chỉ từ những con số này không thể kết luận bạn tập quá sức. '
      'Hãy xem thêm phiếu RPE và triệu chứng sau tập.',
    );
    return b.toString();
  }

  static Future<String> _safetyReason() async {
    final reason = await _safetyBlockReason();
    return reason == null
        ? 'Hiện không tìm thấy lý do chặn trong phiếu/hồ sơ hiện tại. Nếu ứng dụng vẫn chặn, hãy kiểm tra phiếu hôm nay và cảnh báo RPE gần đây trong mục Luyện tập.'
        : 'Health Guardian đang lưu ý: $reason. Không tự bỏ qua cảnh báo để bắt đầu tập.';
  }

  static Future<String> _recovery() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 'Vui lòng đăng nhập để xem lịch sử hồi phục.';
    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final start = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
      ).toUtc().toIso8601String();
      final end = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day + 1,
      ).toUtc().toIso8601String();
      final rows = await Supabase.instance.client
          .from('workout_health_checks')
          .select('rpe,has_symptoms,phase,status')
          .eq('user_id', user.id)
          .gte('created_at', start)
          .lt('created_at', end)
          .limit(100);
      if (rows.any((r) => r['has_symptoms'] == true)) {
        return 'Hôm qua bạn đã báo triệu chứng bất thường. Không tiếp tục tập khi chưa được đánh giá y tế phù hợp.';
      }
      final efforts = rows
          .where((r) => r['phase'] == 'after' && r['rpe'] != null)
          .map((r) => (r['rpe'] as num).toInt())
          .toList();
      if (efforts.isEmpty) {
        return 'Chưa có phiếu RPE sau tập hôm qua để đánh giá mức gắng sức. Không thể khẳng định bạn đã hoặc chưa quá sức.';
      }
      final maxRpe = efforts.reduce((a, b) => a > b ? a : b);
      return maxRpe >= 9
          ? 'Hôm qua bạn tự đánh giá gắng sức rất cao: RPE $maxRpe/10. Hôm nay hãy chú ý hồi phục, không tự tăng cường độ và báo triệu chứng nếu có.'
          : 'Hôm qua bạn ghi nhận ${efforts.length} phiếu RPE, cao nhất $maxRpe/10. RPE là cảm nhận chủ quan, chưa đủ để khẳng định an toàn y tế.';
    } catch (_) {
      return 'Chưa thể truy xuất phiếu RPE từ Supabase. Mình không kết luận tình trạng hồi phục khi thiếu dữ liệu.';
    }
  }

  static Future<String?> _safetyBlockReason() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 'cần đăng nhập để kiểm tra sức khỏe';
    final db = Supabase.instance.client;
    try {
      final profile = await db
          .from('health_guardian_profiles')
          .select('has_health_condition')
          .eq('user_id', user.id)
          .maybeSingle();
      if (profile == null) return 'chưa có hồ sơ an toàn sức khỏe';
      if (profile['has_health_condition'] == true) {
        return 'hồ sơ có bệnh lý/hạn chế cần đánh giá y tế';
      }
      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final daily = await db
          .from('daily_guardian_checks')
          .select('has_symptoms,is_tired,decision_code')
          .eq('user_id', user.id)
          .eq('check_date', today)
          .maybeSingle();
      if (daily == null) return 'chưa có phiếu sức khỏe hôm nay';
      if (daily['has_symptoms'] == true) {
        return 'đã ghi nhận triệu chứng cảnh báo trong hôm nay';
      }
      if (daily['is_tired'] == true) {
        return 'đã ghi nhận mệt/chưa hồi phục trong hôm nay';
      }
      final code = daily['decision_code']?.toString() ?? '';
      if ({
        'SYMPTOMS',
        'MEDICAL_REVIEW',
        'FATIGUE',
        'HIGH_RPE',
        'WARNING_SYMPTOMS',
        'MEDICAL_REVIEW_REQUIRED',
        'FATIGUE_REPORTED',
        'RECENT_HIGH_EFFORT',
      }.contains(code)) {
        return 'phiếu sức khỏe có cảnh báo $code';
      }
      final since = DateTime.now()
          .toUtc()
          .subtract(const Duration(hours: 24))
          .toIso8601String();
      final recent = await db
          .from('workout_health_checks')
          .select('rpe,status,phase,has_symptoms')
          .eq('user_id', user.id)
          .gte('created_at', since)
          .limit(100);
      if (recent.any((r) => r['has_symptoms'] == true)) {
        return 'bạn từng ghi nhận triệu chứng trong 24 giờ gần đây';
      }
      if (recent.any(
        (r) =>
            r['phase'] == 'after' &&
            (((r['rpe'] as num?)?.toInt() ?? 0) >= 9 ||
                r['status'] == 'high_effort'),
      )) {
        return 'phiếu sau tập gần đây có RPE từ 9/10';
      }
      return null;
    } catch (_) {
      return 'không truy xuất được dữ liệu an toàn từ Supabase';
    }
  }
}

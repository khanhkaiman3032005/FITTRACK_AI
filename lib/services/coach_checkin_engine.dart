enum CoachCheckInKind {
  safety,
  medicalReview,
  recovery,
  completed,
  active,
  gentleCheckIn,
}

class CoachCheckIn {
  final CoachCheckInKind kind;
  final String title;
  final String message;
  const CoachCheckIn(this.kind, this.title, this.message);
}

/// Luật thông điệp chủ động; không dùng Gemini và không chẩn đoán y tế.
class CoachCheckInEngine {
  const CoachCheckInEngine._();

  static CoachCheckIn decide({
    required bool hasReportedCondition,
    required bool recentWarningSymptoms,
    required bool recentHighEffort,
    required int completedExercises,
    required int exerciseGoal,
  }) {
    if (recentWarningSymptoms) {
      return const CoachCheckIn(
        CoachCheckInKind.safety,
        'Ưu tiên sức khỏe',
        'Bạn đã báo cáo dấu hiệu bất thường trong lần tập gần đây. '
        'Đừng cố tiếp tục tập. Hãy tìm đánh giá y tế phù hợp; '
        'nếu có dấu hiệu cấp cứu, gọi 115 tại Việt Nam.',
      );
    }
    if (hasReportedCondition) {
      return const CoachCheckIn(
        CoachCheckInKind.medicalReview,
        'Kiểm tra giới hạn vận động',
        'Hồ sơ của bạn có tình trạng sức khỏe ảnh hưởng vận động. '
        'FITTRACK AI không tự xác nhận mức tập an toàn. '
        'Hãy tuân theo hướng dẫn của nhân viên y tế trước khi tập.',
      );
    }
    if (recentHighEffort) {
      return const CoachCheckIn(
        CoachCheckInKind.recovery,
        'Hôm nay bạn hồi phục thế nào?',
        'Buổi tập gần đây được ghi nhận rất gắng sức (RPE từ 9/10). '
        'Bạn đã cảm thấy hồi phục chưa? Đừng vội tăng cường độ. '
        'Đây chỉ là lời nhắc từ nhật ký, không phải kết luận y khoa.',
      );
    }
    if (exerciseGoal > 0 && completedExercises >= exerciseGoal) {
      return const CoachCheckIn(
        CoachCheckInKind.completed,
        'Bạn đã hoàn thành mục tiêu hôm nay!',
        'FITTRACK AI ghi nhận bạn đã đạt mục tiêu bài tập. '
        'Chúc mừng! Hãy dành thời gian nghỉ ngơi và ghi nhận cảm giác sau tập.',
      );
    }
    if (completedExercises > 0) {
      return const CoachCheckIn(
        CoachCheckInKind.active,
        'Bạn đã vận động hôm nay',
        'Mình thấy bạn đã ghi nhận bài tập hôm nay. '
        'Cơ thể bạn cảm thấy thế nào? Nếu đang mệt, bạn có thể nghỉ ngơi.',
      );
    }
    return const CoachCheckIn(
      CoachCheckInKind.gentleCheckIn,
      'Hôm nay bạn thế nào?',
      'Hôm nay FITTRACK AI chưa thấy buổi tập được ghi nhận. '
      'Bạn cảm thấy thế nào? Nếu cần nghỉ, hãy ưu tiên hồi phục nhé.',
    );
  }
}

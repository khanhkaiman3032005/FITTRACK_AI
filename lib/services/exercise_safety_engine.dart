enum GuardianStatus { proceed, rest, blocked }

class GuardianDecision {
  final GuardianStatus status;
  final String code;
  final String message;
  const GuardianDecision(this.status, this.code, this.message);
  bool get canStart => status == GuardianStatus.proceed;
}

class ExerciseSafetyEngine {
  const ExerciseSafetyEngine._();

  static GuardianDecision assess({
    required bool hasProfile,
    required bool hasCondition,
    required bool hasSymptoms,
    required bool veryTired,
    required bool recentVeryHighEffort,
  }) {
    if (!hasProfile) {
      return const GuardianDecision(GuardianStatus.blocked, 'PROFILE_REQUIRED',
          'Cần hoàn thành hồ sơ an toàn sức khỏe trước khi tập.');
    }
    if (hasSymptoms) {
      return const GuardianDecision(GuardianStatus.blocked, 'SYMPTOMS',
          'Bạn đã khai báo triệu chứng bất thường. Không bắt đầu hoặc tiếp tục tập. '
          'Cần đánh giá y tế phù hợp; nếu có dấu hiệu cấp cứu, gọi 115 tại Việt Nam.');
    }
    if (hasCondition) {
      return const GuardianDecision(GuardianStatus.blocked, 'MEDICAL_REVIEW',
          'Hồ sơ ghi nhận bệnh lý hoặc hạn chế vận động. FITTRACK AI không thể '
          'tự xác minh giới hạn do nhân viên y tế chỉ định, nên chưa thể tự động '
          'cho bắt đầu bài tập. Hãy tham khảo nhân viên y tế.');
    }
    if (veryTired) {
      return const GuardianDecision(GuardianStatus.rest, 'FATIGUE',
          'Bạn báo cáo mệt nhiều hoặc chưa hồi phục. Hãy nghỉ và đánh giá lại.');
    }
    if (recentVeryHighEffort) {
      return const GuardianDecision(GuardianStatus.rest, 'HIGH_RPE',
          'Phiếu gần đây ghi nhận RPE từ 9/10. Đây là cờ cảnh báo thận trọng '
          'để kiểm tra hồi phục, không phải chẩn đoán quá sức.');
    }
    return const GuardianDecision(GuardianStatus.proceed, 'NO_REPORTED_FLAG',
        'Phiếu không ghi nhận cảnh báo được hỏi. Điều này không xác nhận '
        'đủ điều kiện y tế để tập luyện.');
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_ai/services/exercise_safety_engine.dart';

void main() {
  GuardianDecision check({bool profile = true, bool condition = false,
    bool symptoms = false, bool tired = false, bool rpe = false}) =>
    ExerciseSafetyEngine.assess(hasProfile: profile, hasCondition: condition,
      hasSymptoms: symptoms, veryTired: tired, recentVeryHighEffort: rpe);

  test('Chưa có hồ sơ: chặn', () {
    expect(check(profile: false).code, 'PROFILE_REQUIRED');
  });
  test('Triệu chứng: chặn', () {
    expect(check(symptoms: true).code, 'SYMPTOMS');
  });
  test('Bệnh lý: yêu cầu đánh giá y tế', () {
    expect(check(condition: true).code, 'MEDICAL_REVIEW');
  });
  test('Triệu chứng ưu tiên hơn bệnh lý', () {
    expect(check(condition: true, symptoms: true).code, 'SYMPTOMS');
  });
  test('Mệt nhiều: nghỉ', () {
    expect(check(tired: true).status, GuardianStatus.rest);
  });
  test('RPE cao gần đây: nghỉ', () {
    expect(check(rpe: true).code, 'HIGH_RPE');
  });
  test('Không báo cảnh báo: tiếp tục quy trình, không phải xác nhận y tế', () {
    expect(check().canStart, isTrue);
  });
}

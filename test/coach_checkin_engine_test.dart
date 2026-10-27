import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_ai/services/coach_checkin_engine.dart';

void main() {
  CoachCheckIn check({
    bool condition = false,
    bool symptoms = false,
    bool high = false,
    int completed = 0,
  }) => CoachCheckInEngine.decide(
    hasReportedCondition: condition,
    recentWarningSymptoms: symptoms,
    recentHighEffort: high,
    completedExercises: completed,
    exerciseGoal: 6,
  );

  test('Triệu chứng luôn ưu tiên', () {
    expect(check(symptoms: true, condition: true, high: true,
      completed: 6).kind, CoachCheckInKind.safety);
  });
  test('Bệnh lý đứng trước RPE và khen thưởng', () {
    expect(check(condition: true, high: true, completed: 6).kind,
      CoachCheckInKind.medicalReview);
  });
  test('RPE cao ưu tiên hơn lời khen', () {
    expect(check(high: true, completed: 6).kind,
      CoachCheckInKind.recovery);
  });
  test('Đủ 6 bài được chúc mừng', () {
    expect(check(completed: 6).kind, CoachCheckInKind.completed);
  });
  test('Tập được 1 bài được động viên', () {
    expect(check(completed: 1).kind, CoachCheckInKind.active);
  });
  test('Chưa tập không bị thúc ép', () {
    final result = check();
    expect(result.kind, CoachCheckInKind.gentleCheckIn);
    expect(result.message, contains('nghỉ'));
  });
}

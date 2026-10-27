import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_ai/services/workout_recommendation_engine.dart';

void main() {
  const weightLoss = WorkoutRecommendationInput(
    currentWeightKg: 90,
    targetWeightKg: 80,
    activeMinutesToday: 0,
    completedExercisesToday: 0,
    dailyActiveMinutesGoal: 60,
  );

  test('Phân loại mục tiêu dựa trên cân nặng đã nhập', () {
    expect(
      WorkoutRecommendationEngine.classifyGoal(weightLoss),
      WorkoutGoal.loseWeight,
    );
    expect(
      WorkoutRecommendationEngine.classifyGoal(
        const WorkoutRecommendationInput(
          currentWeightKg: 60,
          targetWeightKg: 70,
          activeMinutesToday: 0,
          completedExercisesToday: 0,
          dailyActiveMinutesGoal: 60,
        ),
      ),
      WorkoutGoal.gainWeight,
    );
  });

  test('Đề xuất có 3 bài khác nhau, điểm được sắp xếp giảm dần', () {
    final results = WorkoutRecommendationEngine.recommend(weightLoss);
    expect(results, hasLength(3));
    expect(results.map((e) => e.exercise.name).toSet(), hasLength(3));
    expect(results[0].totalScore, greaterThanOrEqualTo(results[1].totalScore));
    expect(results[1].totalScore, greaterThanOrEqualTo(results[2].totalScore));
    for (final item in results) {
      expect(item.totalScore, inInclusiveRange(0, 100));
      final expected =
          item.goalScore * 0.45 +
          item.workloadScore * 0.30 +
          item.timeScore * 0.25;
      expect(item.totalScore, closeTo(expected, 0.000001));
    }
  });

  test('Sau khi vận động nhiều, bài nhẹ được tăng ưu tiên', () {
    const before = WorkoutRecommendationInput(
      currentWeightKg: 70,
      targetWeightKg: 70,
      activeMinutesToday: 0,
      completedExercisesToday: 0,
      dailyActiveMinutesGoal: 60,
    );
    const after = WorkoutRecommendationInput(
      currentWeightKg: 70,
      targetWeightKg: 70,
      activeMinutesToday: 55,
      completedExercisesToday: 2,
      dailyActiveMinutesGoal: 60,
    );
    double scoreOf(String name, WorkoutRecommendationInput input) {
      return WorkoutRecommendationEngine.recommend(
        input,
        limit: 6,
      ).firstWhere((item) => item.exercise.name == name).totalScore;
    }

    final plankBefore = scoreOf('Plank', before);
    final plankAfter = scoreOf('Plank', after);
    expect(plankAfter, greaterThan(plankBefore));
  });

  test('Không có dữ liệu cân nặng thì dùng mục tiêu duy trì', () {
    expect(
      WorkoutRecommendationEngine.classifyGoal(
        const WorkoutRecommendationInput(
          currentWeightKg: 0,
          targetWeightKg: 75,
          activeMinutesToday: 10,
          completedExercisesToday: 0,
          dailyActiveMinutesGoal: 60,
        ),
      ),
      WorkoutGoal.maintain,
    );
  });

  test('Không cần Gemini API, có kết quả ổn định', () {
    final a = WorkoutRecommendationEngine.recommend(weightLoss);
    final b = WorkoutRecommendationEngine.recommend(weightLoss);
    expect(
      a.map((e) => e.exercise.name).toList(),
      b.map((e) => e.exercise.name).toList(),
    );
    expect(
      WorkoutRecommendationEngine.recommend(weightLoss, limit: 0),
      isEmpty,
    );
  });
}

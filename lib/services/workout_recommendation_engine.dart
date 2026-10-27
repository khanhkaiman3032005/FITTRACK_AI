import 'dart:math' as math;

enum WorkoutGoal { loseWeight, gainWeight, maintain }

/// Input dữ liệu: độc lập Flutter, Supabase và Gemini.
class WorkoutRecommendationInput {
  final double currentWeightKg;
  final double targetWeightKg;
  final int activeMinutesToday;
  final int completedExercisesToday;
  final int dailyActiveMinutesGoal;

  const WorkoutRecommendationInput({
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.activeMinutesToday,
    required this.completedExercisesToday,
    required this.dailyActiveMinutesGoal,
  });
}

/// Thông số các bài tập là giả định ban đầu cho cơ chế xếp hạng.
/// Khi tích hợp danh mục bài tập thực tế, cần cập nhật thông số tương ứng.
class WorkoutCandidate {
  final String name;
  final int estimatedMinutes;
  final int relativeIntensity; // 1 = nhẹ, 2 = vừa, 3 = mạnh.
  final int loseWeightFit;
  final int gainWeightFit;
  final int maintainFit;

  const WorkoutCandidate({
    required this.name,
    required this.estimatedMinutes,
    required this.relativeIntensity,
    required this.loseWeightFit,
    required this.gainWeightFit,
    required this.maintainFit,
  });

  int fitFor(WorkoutGoal goal) {
    switch (goal) {
      case WorkoutGoal.loseWeight:
        return loseWeightFit;
      case WorkoutGoal.gainWeight:
        return gainWeightFit;
      case WorkoutGoal.maintain:
        return maintainFit;
    }
  }
}

class RankedWorkout {
  final WorkoutCandidate exercise;
  final double totalScore;
  final double goalScore;
  final double workloadScore;
  final double timeScore;
  final int targetSessionMinutes;

  const RankedWorkout({
    required this.exercise,
    required this.totalScore,
    required this.goalScore,
    required this.workloadScore,
    required this.timeScore,
    required this.targetSessionMinutes,
  });
}

class WorkoutRecommendationEngine {
  const WorkoutRecommendationEngine._();

  /// Danh mục minh họa dựa trên 6 tên bài tập của FITTRACK AI.
  /// Điểm phù hợp và thời lượng cần được hiệu chỉnh qua thử nghiệm.
  static const List<WorkoutCandidate> catalog = [
    WorkoutCandidate(
      name: 'Squat',
      estimatedMinutes: 12,
      relativeIntensity: 2,
      loseWeightFit: 90,
      gainWeightFit: 95,
      maintainFit: 90,
    ),
    WorkoutCandidate(
      name: 'Push Up',
      estimatedMinutes: 10,
      relativeIntensity: 2,
      loseWeightFit: 70,
      gainWeightFit: 90,
      maintainFit: 85,
    ),
    WorkoutCandidate(
      name: 'Lunge',
      estimatedMinutes: 12,
      relativeIntensity: 2,
      loseWeightFit: 85,
      gainWeightFit: 85,
      maintainFit: 85,
    ),
    WorkoutCandidate(
      name: 'Plank',
      estimatedMinutes: 8,
      relativeIntensity: 1,
      loseWeightFit: 75,
      gainWeightFit: 70,
      maintainFit: 90,
    ),
    WorkoutCandidate(
      name: 'Jumping Jack',
      estimatedMinutes: 10,
      relativeIntensity: 3,
      loseWeightFit: 100,
      gainWeightFit: 60,
      maintainFit: 80,
    ),
    WorkoutCandidate(
      name: 'Shoulder Press',
      estimatedMinutes: 12,
      relativeIntensity: 2,
      loseWeightFit: 60,
      gainWeightFit: 95,
      maintainFit: 80,
    ),
  ];

  /// Chỉ suy ra hướng mục tiêu cân nặng; KHÔNG suy ra mức thể lực
  /// hay tình trạng bệnh lý từ BMI hoặc cân nặng.
  static WorkoutGoal classifyGoal(WorkoutRecommendationInput input) {
    if (input.currentWeightKg <= 0 || input.targetWeightKg <= 0) {
      return WorkoutGoal.maintain;
    }
    final delta = input.targetWeightKg - input.currentWeightKg;
    if (delta < -0.5) return WorkoutGoal.loseWeight;
    if (delta > 0.5) return WorkoutGoal.gainWeight;
    return WorkoutGoal.maintain;
  }

  static String goalLabel(WorkoutGoal goal) {
    switch (goal) {
      case WorkoutGoal.loseWeight:
        return 'Giảm cân theo mục tiêu đã nhập';
      case WorkoutGoal.gainWeight:
        return 'Tăng cân theo mục tiêu đã nhập';
      case WorkoutGoal.maintain:
        return 'Duy trì vận động (hoặc chưa có mục tiêu cân nặng)';
    }
  }

  /// Công thức:
  /// Điểm = 0.45 * độ phù hợp mục tiêu
  ///       + 0.30 * độ phù hợp khối lượng vận động hôm nay
  ///       + 0.25 * độ phù hợp thời lượng.
  /// Tất cả tiêu chí thuộc [0,100].
  /// Đây là heuristic có thể giải thích, KHÔNG phải điểm xác suất hay ML.
  static List<RankedWorkout> recommend(
    WorkoutRecommendationInput input, {
    int limit = 3,
    List<WorkoutCandidate> exercises = catalog,
  }) {
    if (limit <= 0 || exercises.isEmpty) return [];
    final goal = classifyGoal(input);
    final active = math.max(0, input.activeMinutesToday);
    final completed = math.max(0, input.completedExercisesToday);
    final remainingMinutes = math.max(0, input.dailyActiveMinutesGoal - active);
    // Đây là thời lượng tham chiếu để xếp hạng, KHÔNG phải thời gian
    // người dùng thực sự rảnh. Sử dụng giá trị mặc định khi hết mục tiêu.
    final sessionTarget = remainingMinutes == 0
        ? 10
        : math.min(25, math.max(8, remainingMinutes));
    // Giảm ưu tiên các bài nặng nếu hôm nay đã vận động nhiều.
    // Không xem đây là đánh giá thể lực hay an toàn y tế cá nhân.
    final desiredIntensity = active >= 30 || completed >= 2 ? 1 : 2;

    final ranked = exercises.map((exercise) {
      final goalScore = exercise.fitFor(goal).clamp(0, 100).toDouble();
      final workloadScore =
          (100 - (exercise.relativeIntensity - desiredIntensity).abs() * 35)
              .clamp(0, 100)
              .toDouble();
      final larger = math.max(sessionTarget, exercise.estimatedMinutes);
      final timeScore = larger <= 0
          ? 0.0
          : (100 -
                    (exercise.estimatedMinutes - sessionTarget).abs() /
                        larger *
                        100)
                .clamp(0, 100)
                .toDouble();

      return RankedWorkout(
        exercise: exercise,
        goalScore: goalScore,
        workloadScore: workloadScore,
        timeScore: timeScore,
        targetSessionMinutes: sessionTarget,
        totalScore: 0.45 * goalScore + 0.30 * workloadScore + 0.25 * timeScore,
      );
    }).toList();

    ranked.sort((a, b) {
      final scoreOrder = b.totalScore.compareTo(a.totalScore);
      return scoreOrder != 0
          ? scoreOrder
          : a.exercise.name.compareTo(b.exercise.name);
    });
    return ranked.take(limit).toList(growable: false);
  }
}

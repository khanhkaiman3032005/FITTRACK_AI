import 'daily_record.dart';

class WeeklyReport {
  final int daysWithData;

  final int totalCaloriesIntake;
  final int totalCaloriesBurned;
  final int totalSteps;
  final int totalWorkoutMinutes;
  final int totalCompletedExercises;

  final double averageCaloriesIntake;
  final double averageCaloriesBurned;
  final double averageSteps;
  final double averageWorkoutMinutes;
  final double averageWater;

  final DailyRecord? mostActiveDay;
  final DailyRecord? leastActiveDay;

  const WeeklyReport({
    required this.daysWithData,
    required this.totalCaloriesIntake,
    required this.totalCaloriesBurned,
    required this.totalSteps,
    required this.totalWorkoutMinutes,
    required this.totalCompletedExercises,
    required this.averageCaloriesIntake,
    required this.averageCaloriesBurned,
    required this.averageSteps,
    required this.averageWorkoutMinutes,
    required this.averageWater,
    required this.mostActiveDay,
    required this.leastActiveDay,
  });
}

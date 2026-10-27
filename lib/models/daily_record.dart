class DailyRecord {
  final DateTime date;

  final int caloriesIntake;
  final int caloriesBurned;

  final int steps;
  final int workoutMinutes;
  final int completedExercises;

  final double water;
  final double bmi;

  const DailyRecord({
    required this.date,
    required this.caloriesIntake,
    required this.caloriesBurned,
    required this.steps,
    required this.workoutMinutes,
    required this.completedExercises,
    required this.water,
    required this.bmi,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'caloriesIntake': caloriesIntake,
      'caloriesBurned': caloriesBurned,
      'steps': steps,
      'workoutMinutes': workoutMinutes,
      'completedExercises': completedExercises,
      'water': water,
      'bmi': bmi,
    };
  }

  factory DailyRecord.fromJson(Map<String, dynamic> json) {
    return DailyRecord(
      date: DateTime.parse(json['date']),
      caloriesIntake: json['caloriesIntake'] ?? 0,
      caloriesBurned: json['caloriesBurned'] ?? 0,
      steps: json['steps'] ?? 0,
      workoutMinutes: json['workoutMinutes'] ?? 0,
      completedExercises: json['completedExercises'] ?? 0,
      water: (json['water'] ?? 0).toDouble(),
      bmi: (json['bmi'] ?? 0).toDouble(),
    );
  }

  DailyRecord copyWith({
    DateTime? date,
    int? caloriesIntake,
    int? caloriesBurned,
    int? steps,
    int? workoutMinutes,
    int? completedExercises,
    double? water,
    double? bmi,
  }) {
    return DailyRecord(
      date: date ?? this.date,
      caloriesIntake: caloriesIntake ?? this.caloriesIntake,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      steps: steps ?? this.steps,
      workoutMinutes: workoutMinutes ?? this.workoutMinutes,
      completedExercises: completedExercises ?? this.completedExercises,
      water: water ?? this.water,
      bmi: bmi ?? this.bmi,
    );
  }
}

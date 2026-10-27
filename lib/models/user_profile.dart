class UserProfile {
  final String name;
  final int age;
  final String gender;

  final double height;
  final double weight;

  final double targetWeight;
  final int dailyStepGoal;
  final double dailyWaterGoal;
  final int dailyCalorieGoal;
  final int dailyActiveMinutesGoal;

  const UserProfile({
    required this.name,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.targetWeight,
    required this.dailyStepGoal,
    required this.dailyWaterGoal,
    required this.dailyCalorieGoal,
    required this.dailyActiveMinutesGoal,
  });

  double get bmi {
    if (height <= 0) return 0;

    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'targetWeight': targetWeight,
      'dailyStepGoal': dailyStepGoal,
      'dailyWaterGoal': dailyWaterGoal,
      'dailyCalorieGoal': dailyCalorieGoal,
      'dailyActiveMinutesGoal': dailyActiveMinutesGoal,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name']?.toString() ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      gender: json['gender']?.toString() ?? 'Nam',
      height: (json['height'] as num?)?.toDouble() ?? 170,
      weight: (json['weight'] as num?)?.toDouble() ?? 65,
      targetWeight: (json['targetWeight'] as num?)?.toDouble() ?? 65,
      dailyStepGoal: (json['dailyStepGoal'] as num?)?.toInt() ?? 10000,
      dailyWaterGoal: (json['dailyWaterGoal'] as num?)?.toDouble() ?? 2.0,
      dailyCalorieGoal: (json['dailyCalorieGoal'] as num?)?.toInt() ?? 2000,
      dailyActiveMinutesGoal:
          (json['dailyActiveMinutesGoal'] as num?)?.toInt() ?? 30,
    );
  }

  UserProfile copyWith({
    String? name,
    int? age,
    String? gender,
    double? height,
    double? weight,
    double? targetWeight,
    int? dailyStepGoal,
    double? dailyWaterGoal,
    int? dailyCalorieGoal,
    int? dailyActiveMinutesGoal,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      targetWeight: targetWeight ?? this.targetWeight,
      dailyStepGoal: dailyStepGoal ?? this.dailyStepGoal,
      dailyWaterGoal: dailyWaterGoal ?? this.dailyWaterGoal,
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
      dailyActiveMinutesGoal:
          dailyActiveMinutesGoal ?? this.dailyActiveMinutesGoal,
    );
  }
}

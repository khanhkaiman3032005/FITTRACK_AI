class HealthData {
  final double height;
  final double weight;
  final int heartRate;
  final double sleepHours;

  final int steps;
  final double water;
  final int activeMinutes;

  const HealthData({
    required this.height,
    required this.weight,
    required this.heartRate,
    required this.sleepHours,
    required this.steps,
    required this.water,
    required this.activeMinutes,
  });

  // giữ nguyên bmi và bmiStatus phía dưới

  double get bmi {
    if (height <= 0 || weight <= 0) {
      return 0;
    }

    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  String get bmiStatus {
    if (bmi < 18.5) {
      return 'Thiếu cân';
    } else if (bmi < 25) {
      return 'Bình thường';
    } else if (bmi < 30) {
      return 'Thừa cân';
    } else {
      return 'Béo phì';
    }
  }
}

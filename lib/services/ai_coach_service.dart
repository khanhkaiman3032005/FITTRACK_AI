import 'workout_recommendation_engine.dart';
import 'health_service.dart';
import 'nutrition_service.dart';
import 'workout_service.dart';
import 'profile_service.dart';

class AiCoachService {
  /// Gom toàn bộ dữ liệu hiện tại của người dùng
  static Map<String, dynamic> getTodayData() {
    final health = HealthService.data;

    return {
      'caloriesIntake': NutritionService.totalCalories,
      'caloriesBurned': WorkoutService.caloriesBurnedToday,
      'steps': health.steps,
      'workoutMinutes': health.activeMinutes,
      'water': health.water,
      'bmi': health.bmi,
      'bmiStatus': health.bmiStatus,
      'completedExercises': WorkoutService.completedToday,
      'workoutGoal': WorkoutService.dailyWorkoutGoal,
    };
  }

  /// Phân tích tình trạng hôm nay
  static String analyzeToday() {
    final data = getTodayData();

    final caloriesIntake = data['caloriesIntake'] as int;
    final caloriesBurned = data['caloriesBurned'] as int;
    final steps = data['steps'] as int;
    final workoutMinutes = data['workoutMinutes'] as int;
    final water = data['water'] as double;
    final bmi = data['bmi'] as double;
    final bmiStatus = data['bmiStatus'] as String;
    final completedExercises = data['completedExercises'] as int;
    final workoutGoal = data['workoutGoal'] as int;
    final profile = ProfileService.profile;

    final stepGoal = profile.dailyStepGoal;
    final waterGoal = profile.dailyWaterGoal;
    final activeGoal = profile.dailyActiveMinutesGoal;

    final buffer = StringBuffer();

    buffer.writeln('📊 Phân tích hôm nay');
    buffer.writeln();
    buffer.writeln('🍽 Calories nạp: $caloriesIntake kcal');
    buffer.writeln('🔥 Calories đốt: $caloriesBurned kcal');
    buffer.writeln('🚶 Bước chân: $steps bước');
    buffer.writeln('⏱ Thời gian vận động: $workoutMinutes phút');
    buffer.writeln('💧 Nước: ${water.toStringAsFixed(1)} L');

    if (bmi > 0) {
      buffer.writeln('⚖️ BMI: ${bmi.toStringAsFixed(1)} - $bmiStatus');
    }

    buffer.writeln('🏋️ Bài tập: $completedExercises/$workoutGoal bài');

    buffer.writeln();
    buffer.writeln('💡 Nhận xét:');

    if (stepGoal > 0) {
      if (steps >= stepGoal) {
        buffer.writeln('• Bạn đã đạt mục tiêu $stepGoal bước hôm nay.');
      } else {
        final remainingSteps = stepGoal - steps;

        buffer.writeln(
          '• Bạn còn $remainingSteps bước để đạt mục tiêu $stepGoal bước.',
        );
      }
    }

    if (activeGoal > 0) {
      if (workoutMinutes >= activeGoal) {
        buffer.writeln('• Bạn đã đạt mục tiêu $activeGoal phút vận động.');
      } else {
        final remainingMinutes = activeGoal - workoutMinutes;

        buffer.writeln(
          '• Bạn còn $remainingMinutes phút vận động để đạt mục tiêu.',
        );
      }
    }

    if (waterGoal > 0) {
      if (water >= waterGoal) {
        buffer.writeln(
          '• Bạn đã đạt mục tiêu ${waterGoal.toStringAsFixed(1)} L nước.',
        );
      } else {
        final remainingWater = waterGoal - water;

        buffer.writeln(
          '• Bạn còn khoảng ${remainingWater.toStringAsFixed(1)} L nước '
          'để đạt mục tiêu.',
        );
      }
    }

    if (completedExercises == 0) {
      buffer.writeln('• Bạn chưa hoàn thành bài tập nào hôm nay.');
    } else if (completedExercises < workoutGoal) {
      final remainingExercises = workoutGoal - completedExercises;

      buffer.writeln(
        '• Bạn còn $remainingExercises bài tập để hoàn thành mục tiêu hôm nay.',
      );
    } else {
      buffer.writeln('• Bạn đã hoàn thành mục tiêu luyện tập hôm nay.');
    }

    return buffer.toString();
  }

  /// Gợi ý tập luyện

  static String suggestWorkout() {
    final data = getTodayData();
    final profile = ProfileService.profile;
    final completed = data['completedExercises'] as int;
    final workoutGoal = data['workoutGoal'] as int;
    final activeMinutes = data['workoutMinutes'] as int;
    final steps = data['steps'] as int;
    final stepGoal = profile.dailyStepGoal;

    final buffer = StringBuffer('🏋️ Gợi ý tập luyện cá nhân hóa\n\n');

    if (workoutGoal > 0 && completed >= workoutGoal) {
      buffer.writeln('🎉 Bạn đã đạt mục tiêu $workoutGoal bài hôm nay.');
      buffer.writeln('Nên ưu tiên nghỉ ngơi hoặc vận động nhẹ theo khả năng.');
      return buffer.toString();
    }

    final input = WorkoutRecommendationInput(
      currentWeightKg: HealthService.data.weight,
      targetWeightKg: profile.targetWeight,
      activeMinutesToday: activeMinutes,
      completedExercisesToday: completed,
      dailyActiveMinutesGoal: profile.dailyActiveMinutesGoal,
    );
    final goal = WorkoutRecommendationEngine.classifyGoal(input);
    final recommended = WorkoutRecommendationEngine.recommend(input);

    buffer.writeln('🎯 ${WorkoutRecommendationEngine.goalLabel(goal)}');
    buffer.writeln('⏱ Đã vận động: $activeMinutes phút hôm nay.');
    buffer.writeln('📋 Đề xuất do thuật toán xếp hạng:');
    buffer.writeln();

    for (var i = 0; i < recommended.length; i++) {
      final item = recommended[i];
      buffer.writeln(
        '${i + 1}. ${item.exercise.name} '
        '— ${item.totalScore.toStringAsFixed(1)}/100 điểm',
      );
      buffer.writeln(
        '   • Mục tiêu: ${item.goalScore.toStringAsFixed(0)}; '
        'khối lượng hôm nay: ${item.workloadScore.toStringAsFixed(0)}; '
        'thời lượng: ${item.timeScore.toStringAsFixed(0)}.',
      );
      buffer.writeln(
        '   • Thời lượng tham khảo: '
        '${item.exercise.estimatedMinutes} phút.',
      );
    }

    buffer.writeln();
    buffer.writeln(
      '🧮 Công thức: 45% mục tiêu + '
      '30% khối lượng vận động + 25% thời lượng.',
    );
    buffer.writeln(
      'Các điểm trên là điểm phù hợp theo quy tắc, '
      'không phải xác suất hoặc kết quả mô hình ML.',
    );
    buffer.writeln('Thời lượng trong bộ máy chỉ là ước lượng để xếp hạng.');
    buffer.writeln();
    if (stepGoal > 0) {
      buffer.writeln('🚶 Tiến độ bước chân: $steps/$stepGoal bước.');
    }
    buffer.writeln(
      '⚠️ Gợi ý tham khảo; hệ thống chưa đánh giá '
      'chấn thương, bệnh lý hoặc kỹ thuật cá nhân.',
    );

    return buffer.toString();
  }

  /// Gợi ý dinh dưỡng
  static String suggestNutrition() {
    final data = getTodayData();

    final caloriesIntake = data['caloriesIntake'] as int;
    final caloriesBurned = data['caloriesBurned'] as int;
    final water = data['water'] as double;

    final calorieGoal = ProfileService.profile.dailyCalorieGoal;
    final waterGoal = ProfileService.profile.dailyWaterGoal;

    final remaining = calorieGoal - caloriesIntake;

    final buffer = StringBuffer();

    buffer.writeln('🥗 Gợi ý dinh dưỡng');
    buffer.writeln();
    buffer.writeln('Bạn đã nạp $caloriesIntake/$calorieGoal kcal hôm nay.');
    buffer.writeln('Calories đốt từ tập luyện: $caloriesBurned kcal.');

    if (remaining > 0) {
      buffer.writeln(
        'Bạn còn khoảng $remaining kcal so với mục tiêu hiện tại.',
      );
    } else {
      buffer.writeln('Bạn đã đạt hoặc vượt mục tiêu calories trong ngày.');
    }

    buffer.writeln();

    if (caloriesIntake < 1000) {
      buffer.writeln(
        '• Lượng calories hiện tại còn thấp so với mục tiêu ngày.',
      );
    } else if (caloriesIntake <= calorieGoal) {
      buffer.writeln('• Lượng calories hiện tại vẫn nằm trong mục tiêu ngày.');
    } else {
      buffer.writeln('• Hôm nay bạn đã vượt mục tiêu calories.');
    }

    if (waterGoal > 0) {
      buffer.writeln();

      buffer.writeln(
        '💧 Nước đã uống: ${water.toStringAsFixed(1)}/${waterGoal.toStringAsFixed(1)} L.',
      );

      if (water < waterGoal) {
        final remainingWater = waterGoal - water;

        buffer.writeln(
          '• Bạn còn ${remainingWater.toStringAsFixed(1)} L nước '
          'để đạt mục tiêu hôm nay.',
        );
      } else {
        buffer.writeln('• Bạn đã đạt mục tiêu uống nước hôm nay.');
      }
    } else {
      buffer.writeln('• Bạn chưa thiết lập mục tiêu uống nước trong hồ sơ.');
    }

    buffer.writeln(
      '• Ưu tiên thực phẩm giàu protein, rau xanh và hạn chế thực phẩm nhiều đường.',
    );

    return buffer.toString();
  }

  /// Fallback khi Gemini không khả dụng.
  /// Phân loại câu hỏi của người dùng và trả lời bằng dữ liệu FITTRACK.
  static String getFallbackResponse(String userMessage) {
    final message = userMessage.toLowerCase().trim();

    // 1. BMI / cân nặng
    if (_containsAny(message, [
      'bmi',
      'cân nặng',
      'cân',
      'kg',
      'béo',
      'gầy',
      'thừa cân',
      'giảm cân',
      'tăng cân',
      'cân nặng mục tiêu',
    ])) {
      return _analyzeWeightAndBmi(message);
    }

    // 2. Calories / dinh dưỡng / ăn uống
    if (_containsAny(message, [
      'ăn',
      'ăn uống',
      'dinh dưỡng',
      'thực phẩm',
      'món ăn',
      'calo',
      'calories',
      'kcal',
      'protein',
      'bữa sáng',
      'bữa trưa',
      'bữa tối',
    ])) {
      return suggestNutrition();
    }

    // 3. Nước
    if (_containsAny(message, [
      'nước',
      'uống nước',
      'bao nhiêu lít',
      'lít nước',
    ])) {
      return _analyzeWater();
    }

    // 4. Bước chân
    if (_containsAny(message, ['bước', 'bước chân', 'đi bộ', 'đi bao nhiêu'])) {
      return _analyzeSteps();
    }

    // 5. Tập luyện
    if (_containsAny(message, [
      'tập',
      'bài tập',
      'workout',
      'luyện tập',
      'thể dục',
      'vận động',
      'squat',
      'push up',
      'plank',
    ])) {
      return suggestWorkout();
    }

    // 6. Mục tiêu / tiến độ
    if (_containsAny(message, [
      'mục tiêu',
      'tiến độ',
      'hoàn thành',
      'đạt chưa',
      'còn thiếu',
      'hôm nay còn',
    ])) {
      return _analyzeGoals();
    }

    // Không xác định rõ -> phân tích tổng quan.
    return analyzeToday();
  }

  /// Kiểm tra câu hỏi có chứa một trong các từ khóa hay không.
  static bool _containsAny(String message, List<String> keywords) {
    return keywords.any(message.contains);
  }

  /// Phân tích BMI và cân nặng.
  static String _analyzeWeightAndBmi(String message) {
    final health = HealthService.data;
    final profile = ProfileService.profile;

    final bmi = health.bmi;
    final bmiStatus = health.bmiStatus;
    final weight = health.weight;
    final targetWeight = profile.targetWeight;

    final buffer = StringBuffer();

    if (weight <= 0 || bmi <= 0) {
      buffer.writeln('⚖️ Phân tích cân nặng & BMI');
      buffer.writeln();
      buffer.writeln(
        'FITTRACK chưa có đủ chiều cao và cân nặng để phân tích BMI.',
      );
      buffer.writeln('Bạn hãy cập nhật thông tin cơ thể trong Hồ sơ cá nhân.');

      return buffer.toString();
    }

    final asksLoseWeight =
        message.contains('giảm cân') ||
        message.contains('giảm kg') ||
        message.contains('giảm ký');

    final asksGainWeight =
        message.contains('tăng cân') ||
        message.contains('tăng kg') ||
        message.contains('tăng ký');

    final asksTarget =
        message.contains('mục tiêu') ||
        message.contains('còn bao nhiêu') ||
        message.contains('bao nhiêu kg');

    // ===== Người dùng muốn giảm cân =====
    if (asksLoseWeight) {
      buffer.writeln('⚖️ Hỗ trợ mục tiêu giảm cân');
      buffer.writeln();
      buffer.writeln('Cân nặng hiện tại: ${weight.toStringAsFixed(1)} kg');
      buffer.writeln('BMI hiện tại: ${bmi.toStringAsFixed(1)} - $bmiStatus');

      if (targetWeight > 0) {
        buffer.writeln(
          'Cân nặng mục tiêu đang đặt: '
          '${targetWeight.toStringAsFixed(1)} kg',
        );

        if (targetWeight >= weight) {
          buffer.writeln();
          buffer.writeln(
            '⚠️ Mục tiêu hiện tại không phải giảm cân: '
            'bạn đang đặt ${weight.toStringAsFixed(1)} kg → '
            '${targetWeight.toStringAsFixed(1)} kg.',
          );
          buffer.writeln(
            'Nếu bạn thực sự muốn giảm cân, hãy cập nhật lại '
            'cân nặng mục tiêu trong Hồ sơ cá nhân.',
          );

          return buffer.toString();
        }

        final remaining = weight - targetWeight;

        buffer.writeln(
          'Bạn cần giảm khoảng ${remaining.toStringAsFixed(1)} kg '
          'để đạt mục tiêu đã đặt.',
        );
      }

      buffer.writeln();
      buffer.writeln('💡 Gợi ý:');
      buffer.writeln('• Theo dõi lượng calories nạp mỗi ngày.');
      buffer.writeln('• Ưu tiên protein, rau xanh và thực phẩm ít chế biến.');
      buffer.writeln('• Duy trì tập luyện và tăng vận động hằng ngày.');
      buffer.writeln('• Theo dõi cân nặng theo xu hướng thay vì chỉ một ngày.');

      return buffer.toString();
    }

    // ===== Người dùng muốn tăng cân =====
    if (asksGainWeight) {
      buffer.writeln('⚖️ Hỗ trợ mục tiêu tăng cân');
      buffer.writeln();
      buffer.writeln('Cân nặng hiện tại: ${weight.toStringAsFixed(1)} kg');
      buffer.writeln('BMI hiện tại: ${bmi.toStringAsFixed(1)} - $bmiStatus');

      if (targetWeight > 0) {
        buffer.writeln(
          'Cân nặng mục tiêu đang đặt: '
          '${targetWeight.toStringAsFixed(1)} kg',
        );

        if (targetWeight <= weight) {
          buffer.writeln();
          buffer.writeln(
            '⚠️ Mục tiêu hiện tại không phải tăng cân: '
            'bạn đang đặt ${weight.toStringAsFixed(1)} kg → '
            '${targetWeight.toStringAsFixed(1)} kg.',
          );
          buffer.writeln(
            'Nếu bạn thực sự muốn tăng cân, hãy cập nhật lại '
            'cân nặng mục tiêu trong Hồ sơ cá nhân.',
          );

          return buffer.toString();
        }

        final remaining = targetWeight - weight;

        buffer.writeln(
          'Bạn còn khoảng ${remaining.toStringAsFixed(1)} kg '
          'để đạt mục tiêu đã đặt.',
        );
      }

      buffer.writeln();
      buffer.writeln('💡 Gợi ý:');
      buffer.writeln('• Đảm bảo chế độ ăn cung cấp đủ năng lượng và protein.');
      buffer.writeln(
        '• Ưu tiên thực phẩm giàu dinh dưỡng thay vì chỉ tăng calories.',
      );
      buffer.writeln('• Kết hợp tập sức mạnh và nghỉ ngơi đầy đủ.');

      return buffer.toString();
    }

    // ===== Hỏi tiến độ cân nặng =====
    if (asksTarget) {
      buffer.writeln('🎯 Tiến độ cân nặng');
      buffer.writeln();
      buffer.writeln('Cân nặng hiện tại: ${weight.toStringAsFixed(1)} kg');

      if (targetWeight <= 0) {
        buffer.writeln('Bạn chưa thiết lập cân nặng mục tiêu.');

        return buffer.toString();
      }

      buffer.writeln(
        'Cân nặng mục tiêu: ${targetWeight.toStringAsFixed(1)} kg',
      );

      final difference = targetWeight - weight;

      if (difference > 0) {
        buffer.writeln(
          'Bạn còn ${difference.toStringAsFixed(1)} kg '
          'để tăng tới mục tiêu.',
        );
      } else if (difference < 0) {
        buffer.writeln(
          'Bạn còn ${difference.abs().toStringAsFixed(1)} kg '
          'để giảm tới mục tiêu.',
        );
      } else {
        buffer.writeln('🎉 Bạn đang ở đúng cân nặng mục tiêu.');
      }

      return buffer.toString();
    }

    // ===== Chỉ hỏi BMI/cân nặng =====
    buffer.writeln('⚖️ Phân tích cân nặng & BMI');
    buffer.writeln();
    buffer.writeln('Cân nặng hiện tại: ${weight.toStringAsFixed(1)} kg');
    buffer.writeln('BMI hiện tại: ${bmi.toStringAsFixed(1)} - $bmiStatus');

    if (targetWeight > 0) {
      buffer.writeln(
        'Cân nặng mục tiêu: ${targetWeight.toStringAsFixed(1)} kg',
      );
    }

    buffer.writeln();
    buffer.writeln(
      'BMI là một chỉ số tham khảo và không phản ánh đầy đủ '
      'thành phần cơ thể.',
    );

    return buffer.toString();
  }

  /// Phân tích lượng nước.
  static String _analyzeWater() {
    final health = HealthService.data;
    final profile = ProfileService.profile;

    final water = health.water;
    final waterGoal = profile.dailyWaterGoal;

    final remaining = waterGoal - water;

    final buffer = StringBuffer();

    buffer.writeln('💧 Theo dõi nước');
    buffer.writeln();
    buffer.writeln(
      'Hôm nay bạn đã uống ${water.toStringAsFixed(1)}'
      '/${waterGoal.toStringAsFixed(1)} L.',
    );

    if (remaining > 0) {
      buffer.writeln(
        'Bạn còn khoảng ${remaining.toStringAsFixed(1)} L '
        'để đạt mục tiêu hôm nay.',
      );
    } else {
      buffer.writeln('Bạn đã đạt mục tiêu uống nước hôm nay.');
    }

    return buffer.toString();
  }

  /// Phân tích bước chân.
  static String _analyzeSteps() {
    final health = HealthService.data;
    final profile = ProfileService.profile;

    final steps = health.steps;
    final stepGoal = profile.dailyStepGoal;
    final remaining = stepGoal - steps;

    final buffer = StringBuffer();

    buffer.writeln('🚶 Theo dõi bước chân');
    buffer.writeln();
    buffer.writeln('Hôm nay bạn đã đi $steps/$stepGoal bước.');

    if (remaining > 0) {
      buffer.writeln('Bạn còn $remaining bước để đạt mục tiêu hôm nay.');
    } else {
      buffer.writeln('Bạn đã đạt mục tiêu bước chân hôm nay.');
    }

    return buffer.toString();
  }

  /// Phân tích tiến độ các mục tiêu hôm nay.
  static String _analyzeGoals() {
    final data = getTodayData();
    final profile = ProfileService.profile;

    final calories = data['caloriesIntake'] as int;
    final steps = data['steps'] as int;
    final water = data['water'] as double;
    final workoutMinutes = data['workoutMinutes'] as int;

    final calorieGoal = profile.dailyCalorieGoal;
    final stepGoal = profile.dailyStepGoal;
    final waterGoal = profile.dailyWaterGoal;
    final activeGoal = profile.dailyActiveMinutesGoal;

    final buffer = StringBuffer();

    buffer.writeln('🎯 Tiến độ mục tiêu hôm nay');
    buffer.writeln();

    buffer.writeln('🍽 Calories: $calories/$calorieGoal kcal');
    buffer.writeln('🚶 Bước chân: $steps/$stepGoal bước');
    buffer.writeln(
      '💧 Nước: ${water.toStringAsFixed(1)}'
      '/${waterGoal.toStringAsFixed(1)} L',
    );
    buffer.writeln('⏱ Vận động: $workoutMinutes/$activeGoal phút');

    buffer.writeln();
    buffer.writeln('💡 Còn lại:');

    final remainingCalories = calorieGoal - calories;
    final remainingSteps = stepGoal - steps;
    final remainingWater = waterGoal - water;
    final remainingActive = activeGoal - workoutMinutes;

    if (remainingCalories > 0) {
      buffer.writeln('• $remainingCalories kcal');
    } else {
      buffer.writeln('• Calories: đã đạt mục tiêu');
    }

    if (remainingSteps > 0) {
      buffer.writeln('• $remainingSteps bước');
    } else {
      buffer.writeln('• Bước chân: đã đạt mục tiêu');
    }

    if (remainingWater > 0) {
      buffer.writeln('• ${remainingWater.toStringAsFixed(1)} L nước');
    } else {
      buffer.writeln('• Nước: đã đạt mục tiêu');
    }

    if (remainingActive > 0) {
      buffer.writeln('• $remainingActive phút vận động');
    } else {
      buffer.writeln('• Vận động: đã đạt mục tiêu');
    }

    return buffer.toString();
  }
}

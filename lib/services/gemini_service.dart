import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'health_service.dart';
import 'nutrition_service.dart';
import 'workout_service.dart';
import 'daily_history_service.dart';
import 'profile_service.dart';

class GeminiService {
  static Future<String> ask(
    String question, {
    List<Map<String, String>> history = const [],
  }) async {
    final health = HealthService.data;
    final profile = ProfileService.profile;

    final recentRecords = DailyHistoryService.getRecentRecords(days: 7);

    final sevenDayHistory = recentRecords.isEmpty
        ? 'Chưa có dữ liệu lịch sử trong 7 ngày gần đây.'
        : recentRecords
              .map((record) {
                final date =
                    '${record.date.day.toString().padLeft(2, '0')}/'
                    '${record.date.month.toString().padLeft(2, '0')}/'
                    '${record.date.year}';

                return '''
Ngày $date:
- Calories nạp: ${record.caloriesIntake} kcal
- Calories đốt: ${record.caloriesBurned} kcal
- Bước chân: ${record.steps}
- Thời gian vận động: ${record.workoutMinutes} phút
- Bài tập hoàn thành: ${record.completedExercises}
- Nước: ${record.water} L
- BMI: ${record.bmi.toStringAsFixed(1)}
''';
              })
              .join('\n');

    final historyText = history.isEmpty
        ? 'Chưa có hội thoại trước đó.'
        : history
              .map((message) {
                final role = message['role'] == 'user'
                    ? 'Người dùng'
                    : 'FITTRACK AI';

                return '$role: ${message['text']}';
              })
              .join('\n');

    final context =
        '''
Bạn là FITTRACK AI Coach, trợ lý sức khỏe và luyện tập trong ứng dụng FITTRACK AI.

Hồ sơ và mục tiêu cá nhân:
- Tên: ${profile.name}
- Tuổi: ${profile.age}
- Giới tính: ${profile.gender}
- Chiều cao: ${profile.height} cm
- Cân nặng hiện tại: ${profile.weight} kg
- Cân nặng mục tiêu: ${profile.targetWeight} kg
- Mục tiêu bước chân: ${profile.dailyStepGoal} bước/ngày
- Mục tiêu uống nước: ${profile.dailyWaterGoal} L/ngày
- Mục tiêu calories: ${profile.dailyCalorieGoal} kcal/ngày
- Mục tiêu vận động: ${profile.dailyActiveMinutesGoal} phút/ngày

Dữ liệu hiện tại của người dùng:
- Calories đã nạp: ${NutritionService.totalCaloriesForDate(DateTime.now())} kcal
- Calories đã đốt: ${WorkoutService.caloriesBurnedToday} kcal
- Bước chân: ${health.steps}
- Thời gian vận động: ${health.activeMinutes} phút
- Nước đã uống: ${health.water} L
- BMI: ${health.bmi}
- Số bài tập hoàn thành: ${WorkoutService.completedToday}/${WorkoutService.dailyWorkoutGoal}

Dữ liệu sức khỏe 7 ngày gần đây:
$sevenDayHistory

Lịch sử hội thoại gần đây:
$historyText

Câu hỏi của người dùng:
$question

Yêu cầu:
- Trả lời bằng tiếng Việt.
- Trả lời ngắn gọn, rõ ràng và dễ hiểu.
- Ưu tiên sử dụng dữ liệu FITTRACK ở trên.
- Không tự bịa thêm dữ liệu người dùng.
- Nếu thiếu dữ liệu cần thiết, hãy nói rõ.
- Với vấn đề y tế nghiêm trọng, không chẩn đoán bệnh; khuyên người dùng tham khảo chuyên gia y tế phù hợp.
- Chỉ trả về văn bản thuần túy (plain text).
- Không sử dụng Markdown.
- Không sử dụng ký hiệu **, *, #, ## hoặc ### để định dạng.
- Có thể sử dụng emoji và dấu gạch đầu dòng • để câu trả lời dễ đọc.
- Khi người dùng hỏi về xu hướng hoặc nhiều ngày, hãy sử dụng dữ liệu lịch sử 7 ngày ở trên.
- Không coi ngày không có bản ghi là ngày có giá trị 0.
- Nếu dữ liệu lịch sử chưa đủ để kết luận, hãy nói rõ số ngày hiện có dữ liệu.
''';
    final backendUrl = kIsWeb
        ? 'http://127.0.0.1:8000/api/gemini'
        : 'http://10.0.2.2:8000/api/gemini';

    try {
      final response = await http
          .post(
            Uri.parse(backendUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'prompt': context}),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        debugPrint(
          'FITTRACK Backend HTTP ${response.statusCode}: ${response.body}',
        );

        if (response.statusCode == 429) {
          return 'FITTRACK AI đã đạt giới hạn yêu cầu Gemini. '
              'Vui lòng thử lại sau.';
        }

        if (response.statusCode == 503) {
          return 'Gemini đang tạm thời không khả dụng. '
              'Vui lòng thử lại sau.';
        }

        return 'Không thể kết nối FITTRACK AI (${response.statusCode}).';
      }

      final data = jsonDecode(response.body);

      if (data['success'] != true) {
        return 'FITTRACK AI chưa tạo được câu trả lời.';
      }

      final rawText = data['text']?.toString();

      if (rawText == null || rawText.trim().isEmpty) {
        return 'FITTRACK AI chưa tạo được câu trả lời.';
      }

      return _cleanResponse(rawText);
    } catch (e) {
      debugPrint('FITTRACK Backend error: $e');

      return 'Không thể kết nối máy chủ FITTRACK AI.';
    }
  }

  static String _cleanResponse(String text) {
    return text
        .replaceAll('***', '')
        .replaceAll('**', '')
        .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^\*\s+', multiLine: true), '• ')
        .trim();
  }
}

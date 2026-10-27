import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_ai/services/coach_hybrid_router.dart';

void main() {
  test('why not permitted to train => safety, not recommendations', () {
    expect(
      CoachHybridRouter.classify('Tại sao tôi không được luyện tập?'),
      'safety_reason',
    );
    expect(
      CoachHybridRouter.classify('Vì sao tôi không thể tập Squat?'),
      'safety_reason',
    );
    expect(CoachHybridRouter.classify('Tại sao bị chặn tập?'), 'safety_reason');
  });
  test('workout recommendations remain recommendations', () {
    expect(CoachHybridRouter.classify('Tôi nên tập bài nào?'), 'recommend');
  });
  test('RSA falls back to Gemini', () {
    expect(
      CoachHybridRouter.classify('Giải thích thuật toán RSA là gì?'),
      isNull,
    );
  });
  test('app usage does not turn into health analysis', () {
    expect(CoachHybridRouter.classify('Đóng rồi mở lại AI Coach'), 'app_usage');
  });
  test('health warnings take precedence', () {
    expect(CoachHybridRouter.classify('Đau ngực khi tập Squat'), 'symptoms');
  });
  test('body and water still route locally', () {
    expect(CoachHybridRouter.classify('BMI của tôi?'), 'body');
    expect(
      CoachHybridRouter.classify('Hôm nay tôi uống bao nhiêu nước?'),
      'water',
    );
  });

  test('Nhận diện phiếu sức khỏe hôm nay', () {
    expect(
      CoachHybridRouter.classify(
        'Hôm nay tôi đã cập nhật phiếu sức khỏe chưa?',
      ),
      'daily_health_check',
    );
  });
}

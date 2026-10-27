import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_ai/services/daily_guardian_service.dart';

void main() {
  test('dayKey uses zero-padded local calendar date', () {
    expect(DailyGuardianService.dayKey(DateTime(2026, 10, 25)), '2026-10-25');
    expect(DailyGuardianService.dayKey(DateTime(2026, 1, 2)), '2026-01-02');
  });
}

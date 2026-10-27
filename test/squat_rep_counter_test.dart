import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_ai/services/squat_rep_counter.dart';

void main() {
  test('Only full down-up creates one rep', () {
    final c = SquatRepCounter(totalSets: 1, targetReps: 2);
    final t = DateTime(2026, 1, 1);
    expect(c.observe(170, t), false);
    expect(c.observe(90, t.add(const Duration(seconds: 1))), false);
    expect(c.observe(95, t.add(const Duration(seconds: 2))), false);
    expect(c.observe(165, t.add(const Duration(seconds: 3))), true);
    expect(c.totalReps, 1);
    expect(c.observe(null, t.add(const Duration(seconds: 4))), false);
    expect(c.observe(90, t.add(const Duration(seconds: 5))), false);
    expect(c.observe(167, t.add(const Duration(seconds: 6))), true);
    expect(c.finished, true);
    expect(c.totalReps, 2);
  });
  test('30-second rest prevents counting between sets', () {
    final c = SquatRepCounter(totalSets: 2, targetReps: 1);
    final t = DateTime(2026, 1, 1);
    c.observe(80, t);
    expect(c.observe(170, t.add(const Duration(seconds: 1))), true);
    expect(c.currentSet, 2);
    expect(c.restSecondsRemaining(t.add(const Duration(seconds: 2))), 29);
    c.observe(80, t.add(const Duration(seconds: 3)));
    expect(c.observe(170, t.add(const Duration(seconds: 4))), false);
    expect(c.totalReps, 1);
    c.observe(80, t.add(const Duration(seconds: 32)));
    expect(c.observe(170, t.add(const Duration(seconds: 33))), true);
    expect(c.finished, true);
  });
  test('Incomplete movements and duplicate frames not counted', () {
    final c = SquatRepCounter(totalSets: 1, targetReps: 5);
    final t = DateTime(2026, 1, 1);
    c.observe(120, t);
    c.observe(170, t.add(const Duration(seconds: 1)));
    expect(c.totalReps, 0);
    c.observe(90, t.add(const Duration(seconds: 2)));
    c.observe(165, t.add(const Duration(seconds: 3)));
    c.observe(165, t.add(const Duration(seconds: 3, milliseconds: 20)));
    expect(c.totalReps, 1);
  });
}

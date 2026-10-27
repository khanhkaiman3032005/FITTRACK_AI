import 'dart:math' as math;

/// Pure logic, independent of the camera implementation. Angle is the knee
/// angle in degrees, measured between hip-knee-ankle (straight leg ~180).
class SquatRepCounter {
  final int totalSets;
  final int targetReps;
  final Duration restDuration;
  int currentSet = 1;
  int repsInSet = 0;
  int totalReps = 0;
  bool _down = false;
  bool finished = false;
  DateTime? restUntil;
  DateTime? _lastRep;

  SquatRepCounter({
    this.totalSets = 3,
    this.targetReps = 10,
    this.restDuration = const Duration(seconds: 30),
  }) : assert(totalSets > 0 && targetReps > 0);

  bool get resting => restUntil != null;
  int restSecondsRemaining(DateTime now) => resting
      ? math.max(0, (restUntil!.difference(now).inMilliseconds / 1000).ceil())
      : 0;

  /// Use only confident, stable landmarks. Null = untracked frame.
  /// One rep is counted ONLY when a deep-enough down phase is followed by up.
  bool observe(double? kneeAngle, DateTime now) {
    if (finished || kneeAngle == null || kneeAngle.isNaN) return false;
    if (resting) {
      if (now.isBefore(restUntil!)) return false;
      restUntil = null;
      _down = false;
    }
    if (kneeAngle < 100) _down = true;
    if (_down && kneeAngle > 158 &&
        (_lastRep == null || now.difference(_lastRep!) >= const Duration(milliseconds: 650))) {
      _down = false;
      _lastRep = now;
      repsInSet++;
      totalReps++;
      if (repsInSet >= targetReps) {
        if (currentSet >= totalSets) {
          finished = true;
        } else {
          currentSet++;
          repsInSet = 0;
          restUntil = now.add(restDuration);
        }
      }
      return true;
    }
    return false;
  }

  static double? jointAngle({
    required double hipX, required double hipY,
    required double kneeX, required double kneeY,
    required double ankleX, required double ankleY,
  }) {
    final a = math.atan2(hipY - kneeY, hipX - kneeX);
    final b = math.atan2(ankleY - kneeY, ankleX - kneeX);
    var deg = (a - b).abs() * 180 / math.pi;
    if (deg > 180) deg = 360 - deg;
    return deg;
  }
}

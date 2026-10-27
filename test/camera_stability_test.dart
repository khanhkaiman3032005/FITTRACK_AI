import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_ai/features/workout/rep_camera/pose_counter_engine.dart';

void main() {
  final t = DateTime(2026);
  test('no rep when whole body is missing', () {
    final d = RepDetector(ExerciseKind.squat);
    for (var i = 0; i < 15; i++) {
      d.update(
        observeExercise(ExerciseKind.squat, {}),
        t.add(Duration(milliseconds: 150 * i)),
      );
    }
    expect(d.reps, 0);
  });
  test('neutral and brief noise never counts', () {
    final d = RepDetector(ExerciseKind.squat);
    for (var i = 0; i < 12; i++) {
      d.update(
        const PoseObservation(
          metric: 140,
          contracted: false,
          extended: false,
          cue: '',
        ),
        t.add(Duration(milliseconds: 150 * i)),
      );
    }
    expect(d.reps, 0);
  });
  test('complete slow cycle counted once', () {
    final d = RepDetector(ExerciseKind.squat);
    var ms = 0;
    for (final angle in <double>[
      170.0,
      170.0,
      170.0,
      90.0,
      90.0,
      90.0,
      90.0,
      90.0,
      170.0,
      170.0,
      170.0,
      170.0,
      170.0,
    ]) {
      d.update(
        PoseObservation(
          metric: angle,
          contracted: angle < 112,
          extended: angle > 158,
          cue: '',
        ),
        t.add(Duration(milliseconds: ms)),
      );
      ms += 180;
    }
    expect(d.reps, 1);
  });
  test('missing landmarks abort pending repetition', () {
    final d = RepDetector(ExerciseKind.pushUp);
    d.update(const PoseObservation(contracted: true, cue: ''), t);
    d.update(
      const PoseObservation(contracted: true, cue: ''),
      t.add(const Duration(milliseconds: 180)),
    );
    d.update(
      const PoseObservation(cue: 'lost'),
      t.add(const Duration(milliseconds: 360)),
    );
    d.update(
      const PoseObservation(extended: true, cue: ''),
      t.add(const Duration(milliseconds: 540)),
    );
    d.update(
      const PoseObservation(extended: true, cue: ''),
      t.add(const Duration(milliseconds: 720)),
    );
    expect(d.reps, 0);
  });
  test('all exercise kinds remain supported', () {
    for (final kind in ExerciseKind.values) {
      expect(observeExercise(kind, {}).cue, isNotEmpty);
    }
  });
}

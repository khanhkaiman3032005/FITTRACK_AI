import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_ai/features/workout/rep_camera/pose_counter_engine.dart';

void main() {
  test('name classifier resolves all six exercises', () {
    for(final name in ['Squat','Push Up','Lunge','Plank','Jumping Jack','Shoulder Press']) {
      expect(exerciseKindFromName(name), isNotNull);
    }
  });
  test('angle is 180 degrees for aligned points', () {
    expect(jointAngle(const JointPoint(0,0),const JointPoint(1,0),const JointPoint(2,0)),closeTo(180,.01));
  });
  test('no counts for missing landmarks', () {
    final d=RepDetector(ExerciseKind.squat);
    for(int i=0;i<12;i++){
      expect(d.update(const PoseObservation(cue:'No person'),DateTime(2026,1,1).add(Duration(milliseconds:i*150))),false);
    }
    expect(d.reps,0);
  });
  test('counts one contracted-to-extended full cycle only', () {
    final d=RepDetector(ExerciseKind.squat);
    final t=DateTime(2026,1,1);
    for(int i=0;i<2;i++){
      d.update(const PoseObservation(contracted:true,cue:'down'),t.add(Duration(milliseconds:i*200)));
    }
    for(int i=0;i<2;i++){
      d.update(const PoseObservation(extended:true,cue:'up'),t.add(Duration(milliseconds:400+i*200)));
    }
    expect(d.reps,1);
    for(int i=0;i<6;i++){
      d.update(const PoseObservation(extended:true,cue:'up'),t.add(Duration(milliseconds:800+i*200)));
    }
    expect(d.reps,1);
  });
  test('landmark confidence suppresses angle', () {
    expect(jointAngle(const JointPoint(0,0,.3),const JointPoint(1,0),const JointPoint(2,0)),isNull);
  });
  test('plank has no rep cycle', () {
    final d=RepDetector(ExerciseKind.plank);
    expect(d.update(const PoseObservation(contracted:true,extended:true,cue:'plank'),DateTime(2026)),false);
    expect(d.reps,0);
  });
}

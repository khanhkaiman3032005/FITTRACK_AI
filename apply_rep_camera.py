#!/usr/bin/env python3
"""Safely wire AI Camera into the existing ActiveWorkoutScreen. No whole-file replacement."""
from pathlib import Path
import sys, shutil, datetime, re
root=Path(__file__).resolve().parent.parent.parent # when script lives at project root, use cwd instead
root=Path.cwd()
file=root/'lib/features/workout/active_workout_screen.dart'
if not (root/'pubspec.yaml').exists() or not file.exists():
    sys.exit('ERROR: Run from Flutter project root (pubspec.yaml required).')
s=file.read_text(encoding='utf-8')
if 'CameraRepCounterScreen' in s:
    sys.exit('Already integrated. Nothing changed.')
needed=['class _ActiveWorkoutScreenState','Future<void> _finishWorkout()','Widget build(BuildContext context)','bool _guardianAuthorized']
missing=[x for x in needed if x not in s]
if missing:
    sys.exit('ERROR: File layout differs from reference: '+str(missing)+'; nothing changed.')
anchor='  Future<void> _finishWorkout() async {'
if s.count(anchor)!=1:
    sys.exit('ERROR: Could not safely locate workout finish method; nothing changed.')
new_method='''  Future<void> _startCameraCounter() async {
    if (_isFinishing || !_guardianAuthorized) return;
    // The camera is only entered from the already approved workout session.
    setState(() => _isRunning = false);
    final result = await Navigator.push<CameraWorkoutResult>(
      context,
      MaterialPageRoute(
        builder: (_) => CameraRepCounterScreen(
          exerciseName: widget.exercise.name,
          sets: widget.exercise.sets,
          repsPerSet: widget.exercise.repsPerSet,
        ),
      ),
    );
    if (!mounted) return;
    if (result == null) return; // Return to paused manual controls.
    if (result.stoppedForSymptoms) {
      Navigator.pop(context, false); // No calories, no progress.
      return;
    }
    if (result.perSet.length != widget.exercise.sets) return;
    setState(() {
      _seconds += result.elapsedSeconds;
      _currentSet = widget.exercise.sets;
      _totalReps = result.totalReps - result.perSet.last;
      _reps = result.perSet.last;
    });
    // Existing finish flow prompts for RPE and persists calories/history.
    await _finishWorkout();
  }

'''
# inject camera action before existing pause button; exact anchor
button_anchor='''                    SizedBox(
                      height: 55,
                      child: FilledButton.icon(
                        onPressed: _isFinishing ? null : _toggleTimer,'''
if s.count(button_anchor)!=1:
    sys.exit('ERROR: Cannot safely locate pause button; nothing changed.')
button='''                    SizedBox(
                      height: 55,
                      child: FilledButton.icon(
                        onPressed: _isFinishing ? null : _startCameraCounter,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('AI Camera — Tự đếm bài tập'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF089BC2),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

'''
s="import 'rep_camera/camera_rep_counter_screen.dart';\n"+s
s=s.replace(anchor,new_method+anchor,1)
s=s.replace(button_anchor,button+button_anchor,1)
# backup adjacent to project (no analyzer picking backup Dart files)
backup_dir=root.parent/(root.name+'_rep_camera_backup_'+datetime.datetime.now().strftime('%Y%m%d_%H%M%S'))
backup_dir.mkdir(exist_ok=False)
shutil.copy2(file,backup_dir/file.name)
file.write_text(s,encoding='utf-8')
print('PATCH OK:',file)
print('BACKUP (outside Flutter project):',backup_dir)
print('NEXT: flutter pub add camera google_mlkit_pose_detection && flutter analyze && flutter test')

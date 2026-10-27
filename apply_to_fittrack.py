"""Apply a minimal guarded patch to the EXISTING FITTRACK AI v1 Workout files.
Run from the root of FITTRACK AI after extracting the package into the project.
Makes dated backups, refuses to patch an unrecognized source.
"""
from pathlib import Path
import shutil
import sys
import re
from datetime import datetime

root=Path.cwd()
active=root/'lib/features/workout/active_workout_screen.dart'
detail=root/'lib/features/workout/exercise_detail_screen.dart'
if not active.exists() or not detail.exists():
    sys.exit('ERROR: Run this script from FITTRACK AI project root (folder containing pubspec.yaml).')
if not (root/'pubspec.yaml').exists():
    sys.exit('ERROR: pubspec.yaml was not found.')

original=active.read_text(encoding='utf-8')
s=original
if "import '../../services/health_guardian_service.dart';" not in s:
    s=s.replace("import '../../services/workout_service.dart';",
      "import '../../services/workout_service.dart';\nimport '../../services/health_guardian_service.dart';",1)
if "import '../../services/health_guardian_service.dart';" not in s:
    sys.exit('ERROR: Could not locate service imports in active_workout_screen.dart')

anchor='  bool _isFinishing = false;'
if '_guardianAuthorized' not in s:
    if anchor not in s: sys.exit('ERROR: Could not locate _isFinishing flag')
    s=s.replace(anchor,anchor+'\n  bool _guardianAuthorized = false;',1)

old="""  @override
  void initState() {
    super.initState();
    _startTimer();
  }
"""
new="""  @override
  void initState() {
    super.initState();
    try {
      _guardianAuthorized = HealthGuardianService.consumeApproval(widget.exercise.name);
    } catch (_) {
      _guardianAuthorized = false;
    }
    if (_guardianAuthorized) _startTimer();
  }
"""
if old in s: s=s.replace(old,new,1)
elif new not in s: sys.exit('ERROR: Cannot safely recognize initState in active_workout_screen.dart')

old_end='if (_currentSet >= 3) {'
if old_end in s:
    s=s.replace(old_end,'if (_currentSet >= widget.exercise.sets) {',1)

# Khi người dùng đóng phiếu sau tập: không tự khởi động lại đồng hồ.
null_block = re.search(r"if\s*\(safeToComplete\s*==\s*null\)\s*\{(?P<body>.*?)\n\s*\}", s, re.S)
if null_block and '_startTimer();' in null_block.group('body'):
    new_body = re.sub(r"_isRunning\s*=\s*true\s*;", "_isRunning = false;", null_block.group('body'))
    new_body = new_body.replace('_startTimer();', '')
    s = s[:null_block.start('body')] + new_body + s[null_block.end('body'):]

if 'if (safeToComplete == null)' not in s:
    sys.exit('ERROR: v1 post-workout safety assessment was not found. Did you finish Health Guardian 1.0?')

build_anchor='  Widget build(BuildContext context) {\n    final exercise = widget.exercise;'
block='''  Widget build(BuildContext context) {
    if (!_guardianAuthorized) {
      return Scaffold(
        backgroundColor: const Color(0xFF080D19),
        appBar: AppBar(title: const Text('Yêu cầu kiểm tra sức khỏe')),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.shield_outlined, size: 50, color: Colors.orangeAccent),
            const SizedBox(height: 16),
            const Text('Bạn cần hoàn thành phiếu kiểm tra trước khi bắt đầu tập.',
              textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton(onPressed: () => Navigator.pop(context),
              child: const Text('Quay lại')),
          ]),
        )),
      );
    }
    final exercise = widget.exercise;'''
if 'if (!_guardianAuthorized) {' not in s:
    if build_anchor not in s: sys.exit('ERROR: Cannot safely locate main build method')
    s=s.replace(build_anchor,block,1)

if 'consumeApproval(widget.exercise.name)' not in s or 'if (!_guardianAuthorized)' not in s:
    sys.exit('ERROR: Safety guard could not be verified')

# ExerciseDetailScreen should continue using PreWorkoutCheckScreen, not direct workout.
d=detail.read_text(encoding='utf-8')
if "import 'pre_workout_check_screen.dart';" not in d:
    d=d.replace("import 'active_workout_screen.dart';", "import 'pre_workout_check_screen.dart';",1)
d=d.replace('ActiveWorkoutScreen(exercise: exercise)', 'PreWorkoutCheckScreen(exercise: exercise)')
if 'PreWorkoutCheckScreen(exercise: exercise)' not in d:
    sys.exit('ERROR: Cannot confirm ExerciseDetailScreen routes via PreWorkoutCheckScreen')

stamp=datetime.now().strftime('%Y%m%d_%H%M%S')
backup=root/f'hg2_backup_{stamp}'
backup.mkdir()
shutil.copy2(active,backup/active.name)
shutil.copy2(detail,backup/detail.name)
active.write_text(s,encoding='utf-8')
detail.write_text(d,encoding='utf-8')
print('PATCH APPLIED: safe workout gate installed.')
print('BACKUPS:', backup)
print('NEXT: flutter analyze && flutter test test/exercise_safety_engine_test.dart')

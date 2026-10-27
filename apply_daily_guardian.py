#!/usr/bin/env python3
"""FitTrack AI daily guardian patch. Run from project root after copying lib/."""
from pathlib import Path
import datetime
import shutil
import sys

root = Path.cwd().resolve()
main = root / 'lib/main.dart'
detail = root / 'lib/features/workout/exercise_detail_screen.dart'
workout = root / 'lib/features/workout/workout_screen.dart'
required = [
    root / 'lib/services/daily_guardian_service.dart',
    root / 'lib/features/workout/daily_guardian_gate.dart',
    root / 'lib/features/workout/daily_guardian_form_screen.dart',
    root / 'lib/widgets/guardian_profile_shortcut.dart',
    root / 'lib/services/coach_checkin_service.dart',
    root / 'lib/services/health_guardian_service.dart',
    root / 'lib/features/workout/active_workout_screen.dart',
]
if not (root / 'pubspec.yaml').is_file():
    sys.exit('ERROR: Chạy tại thư mục fittrack_ai có pubspec.yaml')
for p in [main, detail, workout, *required]:
    if not p.is_file():
        sys.exit(f'ERROR: Thiếu file {p.relative_to(root)}')

orig_main = main.read_text(encoding='utf-8-sig')
orig_detail = detail.read_text(encoding='utf-8-sig')
orig_workout = workout.read_text(encoding='utf-8-sig')
if 'DailyGuardianWorkoutGate(' in orig_workout or 'DailyGuardianExerciseGate(' in orig_detail:
    sys.exit('ERROR: Có vẻ bản daily đã áp dụng. Không chạy lại script.')

# Update exact old route expressions, keeping the rest of main.dart untouched.
profile_needle = 'AppRoutes.profile: (context) => const ProfileScreen(),'
detail_needle = 'PreWorkoutCheckScreen(exercise: exercise)'
if (orig_main.count(profile_needle) != 1 or
    orig_detail.count(detail_needle) != 1 or
    orig_workout.count('class WorkoutScreen extends StatefulWidget {') != 1 or
    orig_workout.count('class _WorkoutScreenState extends State<WorkoutScreen> {') != 1):
    sys.exit('ERROR: Route hiện tại khác bản user gửi. Không thay đổi file. Gửi main.dart/exercise_detail_screen.dart để kiểm tra.')

modified_main = orig_main.replace(profile_needle,
    'AppRoutes.profile: (context) =>\n'
    '            const GuardianProfileShortcut(child: ProfileScreen()),')
insert_main = "import 'widgets/guardian_profile_shortcut.dart';\n"
modified_main = insert_main + modified_main
modified_detail = orig_detail.replace(detail_needle,
    'DailyGuardianExerciseGate(exercise: exercise)')
modified_detail = modified_detail.replace("import 'pre_workout_check_screen.dart';",
    "import 'daily_guardian_gate.dart';")
modified_workout = orig_workout.replace('class WorkoutScreen extends StatefulWidget {',
    'class WorkoutCatalogScreen extends StatefulWidget {')
modified_workout = modified_workout.replace('const WorkoutScreen({super.key});',
    'const WorkoutCatalogScreen({super.key});')
modified_workout = modified_workout.replace('State<WorkoutScreen> createState() => _WorkoutScreenState();',
    'State<WorkoutCatalogScreen> createState() => _WorkoutCatalogScreenState();')
modified_workout = modified_workout.replace('class _WorkoutScreenState extends State<WorkoutScreen> {',
    'class _WorkoutCatalogScreenState extends State<WorkoutCatalogScreen> {')
modified_workout = "import 'daily_guardian_gate.dart';\n" + modified_workout
modified_workout += "\n/// Guard EVERY entrance including direct Navigator routes.\nclass WorkoutScreen extends StatelessWidget {\n  const WorkoutScreen({super.key});\n  @override\n  Widget build(BuildContext context) => const DailyGuardianWorkoutGate();\n}\n"
if "import 'daily_guardian_gate.dart';" not in modified_detail:
    sys.exit('ERROR: Không tìm thấy import pre_workout_check_screen.dart để đổi đúng cách.')

# Backups OUTSIDE project so flutter analyze does not analyze them.
backup_root = root.parent / ('FITTRACK_HG_DAILY_BACKUP_' + datetime.datetime.now().strftime('%Y%m%d_%H%M%S'))
backup_root.mkdir(parents=True, exist_ok=False)
shutil.copy2(main, backup_root / 'main.dart')
shutil.copy2(detail, backup_root / 'exercise_detail_screen.dart')
shutil.copy2(workout, backup_root / 'workout_screen.dart')
try:
    main.write_text(modified_main, encoding='utf-8')
    detail.write_text(modified_detail, encoding='utf-8')
    workout.write_text(modified_workout, encoding='utf-8')
except Exception:
    shutil.copy2(backup_root / 'main.dart', main)
    shutil.copy2(backup_root / 'exercise_detail_screen.dart', detail)
    shutil.copy2(backup_root / 'workout_screen.dart', workout)
    raise
print('PATCH COMPLETE: Dashboard/AI Coach unchanged. Daily gate installed inside WorkoutScreen and exercise detail.')
print('Profile now has a Health Guardian shortcut.')
print('BACKUP OUTSIDE PROJECT:', backup_root)
print('NEXT: dart format lib/main.dart lib/features/workout/workout_screen.dart lib/features/workout/exercise_detail_screen.dart')
print('NEXT: flutter analyze && flutter test')

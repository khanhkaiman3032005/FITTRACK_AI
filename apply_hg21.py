"""Guarded one-time FITTRACK HG2.1 integration. Run at project root.
Does not overwrite Workout UI. Backups are created outside project root.
"""
from pathlib import Path
import sys, shutil, datetime, re

root = Path.cwd()
if not (root / 'pubspec.yaml').exists():
    sys.exit('ERROR: Open a terminal at the FITTRACK AI root (pubspec.yaml).')

main = root/'lib/main.dart'
pre = root/'lib/features/workout/pre_workout_check_screen.dart'
service = root/'lib/services/health_guardian_service.dart'
for p in (main,pre,service):
    if not p.is_file(): sys.exit(f'ERROR: Missing {p}. No changes made.')

originals = {p:p.read_text(encoding='utf-8') for p in (main,pre,service)}
changes = dict(originals)

# 1. Service: append optional decisionCode and store in new SQL column.
p=service;s=changes[p]
if "'decision_code':" not in s:
    needle = '    int? rpe,\n  }) async {'
    if s.count(needle)!=1: sys.exit('ERROR: Cannot safely identify saveCheck signature; nothing changed.')
    s=s.replace(needle,'    int? rpe,\n    String? decisionCode,\n  }) async {',1)
    needle = "      'rpe': rpe,"
    if s.count(needle)!=1:sys.exit('ERROR: Cannot find saveCheck payload; nothing changed.')
    replace = """      'rpe': rpe,
      'decision_code': decisionCode ??
          (hasSymptoms ? (phase == 'after' ? 'SYMPTOMS_AFTER' :
              'USER_REPORTED_SYMPTOMS') :
           (phase == 'after' && status == 'high_effort' ? 'HIGH_RPE' :
            (phase == 'after' && status == 'completed' ? 'NO_REPORTED_FLAG' :
             null))),"""
    s=s.replace(needle,replace,1)
changes[p]=s

# 2. Pre-workout: preserve exact engine decision code for each check.
p=pre;s=changes[p]
if 'decisionCode: decision.code' not in s:
    needle = '        hasSymptoms: _symptoms!, isTired: _tired!,\n'
    if s.count(needle)!=1:sys.exit('ERROR: Unknown pre-workout saveCheck format; nothing changed.')
    s=s.replace(needle,needle+'        decisionCode: decision.code,\n',1)
changes[p]=s

# 3. Wrap existing Dashboard and AiCoach named routes for opt-in-on-app-open greeting.
p=main;s=changes[p]
if 'coach_proactive_wrapper.dart' not in s:
    mark="import 'package:flutter/material.dart';"
    if mark not in s:sys.exit('ERROR: main.dart imports differ; nothing changed.')
    s=s.replace(mark,mark+"\nimport 'widgets/coach_proactive_wrapper.dart';",1)
for name,widget in [('dashboard','DashboardScreen'),('aiCoach','AiCoachScreen')]:
    pattern=rf'(AppRoutes\.{name}\s*:\s*\(context\)\s*=>\s*)const\s+{widget}\(\)'
    if f'CoachProactiveWrapper(child: {widget}()' not in s:
        s,n=re.subn(pattern,rf'\1const CoachProactiveWrapper(child: {widget}())',s,count=1)
        if n!=1:sys.exit(f'ERROR: Could not recognize AppRoutes.{name}; no files changed.')
changes[p]=s

# All guards pass. Backup OUTSIDE project root to prevent Flutter analyzer errors.
stamp=datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
backup=root.parent/f'FITTRACK_HG21_BACKUP_{stamp}'
backup.mkdir(parents=False,exist_ok=False)
try:
    for p in originals:
        if originals[p]!=changes[p]:
            target=backup/p.relative_to(root)
            target.parent.mkdir(parents=True,exist_ok=True)
            target.write_text(originals[p],encoding='utf-8')
    for p in originals:
        if originals[p]!=changes[p]:p.write_text(changes[p],encoding='utf-8')
except Exception as e:
    for p,data in originals.items():p.write_text(data,encoding='utf-8')
    sys.exit(f'ERROR: Rolled back modifications: {e}')
print('HG2.1 integration completed.')
print('Backups outside Flutter project:',backup)
print('Next: dart format lib/services/health_guardian_service.dart lib/features/workout/pre_workout_check_screen.dart lib/main.dart')
print('Then: flutter analyze && flutter test test/coach_checkin_engine_test.dart')

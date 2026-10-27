"""Patch only the existing V3.0 router and pubspec. Safe/idempotent.
Put this script in project root (same level as pubspec.yaml). Backup outside project.
"""
from pathlib import Path
import shutil, datetime, sys
root=Path.cwd()
router=root/'lib/services/coach_hybrid_router.dart'
pubspec=root/'pubspec.yaml'
if not router.is_file() or not pubspec.is_file():
    sys.exit('ERROR: run from Flutter root; missing router or pubspec.yaml')
s=router.read_text(encoding='utf8'); p=pubspec.read_text(encoding='utf8')
anchor='final intent = classify(question);'
if 'TrainedIntentClassifier.classify(question)' in s:
    print('Router already patched; no repeat edits.');sys.exit(0)
if s.count(anchor)!=1:
    sys.exit('ERROR: router signature changed; do not patch. Send current router for review.')
if not any(line == 'flutter:' for line in p.splitlines()):
    sys.exit('ERROR: flutter: section missing in pubspec.yaml')
assets_line='    - assets/ai/intent_nb.json'
if assets_line not in p:
    lines=p.splitlines(keepends=True)
    start=next((i for i,line in enumerate(lines) if line.strip()=='flutter:' and not line.startswith(' ')),None)
    if start is None:sys.exit('ERROR: flutter: must be a root-level key')
    next_root=next((i for i in range(start+1,len(lines)) if lines[i].strip() and not lines[i].startswith((' ','#','\n'))),len(lines))
    existing=next((i for i in range(start+1,next_root) if lines[i].strip()=='assets:'),None)
    if existing is not None:
        lines.insert(existing+1,assets_line+'\n')
    else:
        lines.insert(start+1,'  assets:\n'+assets_line+'\n')
    p=''.join(lines)
backup=root.parent/('fittrack_ai31_backup_'+datetime.datetime.now().strftime('%Y%m%d_%H%M%S'))
backup.mkdir()
shutil.copy2(router,backup/'coach_hybrid_router.dart')
shutil.copy2(pubspec,backup/'pubspec.yaml')
s=s.replace("import 'package:supabase_flutter/supabase_flutter.dart';", "import 'package:supabase_flutter/supabase_flutter.dart';\nimport 'trained_intent_classifier.dart';",1)
s=s.replace(anchor,'final intent = classify(question) ?? await TrainedIntentClassifier.classify(question);',1)
router.write_text(s,encoding='utf8');pubspec.write_text(p,encoding='utf8')
print('PATCH APPLIED. Backup (outside Flutter):',backup)
print('Model is used only if the existing safe rules do not recognize the question.')

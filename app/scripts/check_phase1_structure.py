#!/usr/bin/env python3
from pathlib import Path
import plistlib
import sys

ROOT = Path(__file__).resolve().parents[1]
required = [
    'project.yml',
    'Sources/Shared/MawaFlowEngine.swift',
    'Sources/MawaFlow/MawaFlowApp.swift',
    'Sources/MawaFlow/ContentView.swift',
    'Sources/MawaFlow/Info.plist',
    'Sources/MawaKeyboard/KeyboardViewController.swift',
    'Sources/MawaKeyboard/Info.plist',
    'README.md',
]

errors = []
for rel in required:
    path = ROOT / rel
    if not path.exists():
        errors.append(f'Missing {rel}')

for rel in ['Sources/MawaFlow/Info.plist', 'Sources/MawaKeyboard/Info.plist']:
    path = ROOT / rel
    if path.exists():
        try:
            plistlib.loads(path.read_bytes())
        except Exception as exc:
            errors.append(f'Invalid plist {rel}: {exc}')

keyboard = (ROOT / 'Sources/MawaKeyboard/KeyboardViewController.swift').read_text()
for needle in ['textDocumentProxy.insertText', 'advanceToNextInputMode', 'MawaFlowEngine.generate']:
    if needle not in keyboard:
        errors.append(f'Keyboard missing {needle}')

engine = (ROOT / 'Sources/Shared/MawaFlowEngine.swift').read_text()
for mode in ['case auto', 'case dictate', 'case reply', 'case prompt', 'case rewrite', 'case ask']:
    if mode not in engine:
        errors.append(f'Engine missing {mode}')

project = (ROOT / 'project.yml').read_text()
for target in ['MawaFlow:', 'MawaKeyboard:', 'com.apple.keyboard-service']:
    if target == 'com.apple.keyboard-service':
        if target not in (ROOT / 'Sources/MawaKeyboard/Info.plist').read_text():
            errors.append('Keyboard Info.plist missing extension point')
    elif target not in project:
        errors.append(f'project.yml missing target {target}')

if errors:
    print('Phase 1 structure check failed:')
    for error in errors:
        print('-', error)
    sys.exit(1)

print('Phase 1 structure check passed.')
print(f'Root: {ROOT}')
print(f'Files checked: {len(required)}')

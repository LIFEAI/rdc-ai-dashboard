#!/usr/bin/env bash
# ============================================================
#  RDC AI Dashboard — Linux / VM Installer
#  Used for testing on the Cowork Linux VM
# ============================================================
set -e
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo "[OK] Project dir: $PROJECT_DIR"

# ── Python check ─────────────────────────────────────────────
python3 --version

# ── Install deps (break-system-packages for VM/headless env) ──
echo "[..] Installing dependencies..."
pip install --break-system-packages -q -r "$PROJECT_DIR/requirements.txt"
echo "[OK] Done."

# ── Quick smoke test (no display needed) ─────────────────────
echo "[..] Running import smoke tests..."
cd "$PROJECT_DIR/src"
python3 -c "
import sys
sys.path.insert(0, '.')
results = []

# mru_manager
try:
    import mru_manager as mru
    s = mru.load_settings()
    mru.add_file('/tmp/test.txt')
    mru.add_folder('/tmp')
    mru.add_operation('test op')
    assert mru.get_recent_files()[0] == '/tmp/test.txt'
    results.append('  ✓ mru_manager')
except Exception as e:
    results.append(f'  ✗ mru_manager: {e}')

# rdc_archive
try:
    import rdc_archive
    import re
    tests = [
        ('RDC_Overview_V1.0.docx', True),
        ('TPF_Exec_Sum_V3.19.docx', True),
        ('LifeAI_Overview_V1.4.pptx', True),
        ('random file.docx', False),
        ('RDC_Budget_V1.2.xlsx', True),
        ('no_version.pdf', False),
        ('LBS_Deck_v7.3_copy.pptx', True),
    ]
    ok = True
    for fname, expect in tests:
        got = rdc_archive._parse_version(fname) is not None
        status = '✓' if got == expect else '✗'
        if got != expect:
            ok = False
        results.append(f'    {status} archive regex: {fname}')
    results.append('  ✓ rdc_archive' if ok else '  ✗ rdc_archive (regex failures)')
except Exception as e:
    results.append(f'  ✗ rdc_archive: {e}')

# rdc_training_sync
try:
    import rdc_training_sync
    tests = [
        ('RDC_Primer_TRAIN_V3.1.docx', True),
        ('TPF_Exec_TRAIN_v2.0.pdf', True),
        ('LifeAI_Overview_V1.4.pptx', False),
    ]
    ok = True
    for fname, expect in tests:
        got = rdc_training_sync._parse_train(fname) is not None
        status = '✓' if got == expect else '✗'
        if got != expect:
            ok = False
        results.append(f'    {status} train regex: {fname}')
    results.append('  ✓ rdc_training_sync' if ok else '  ✗ rdc_training_sync')
except Exception as e:
    results.append(f'  ✗ rdc_training_sync: {e}')

# rdc_scaffold
try:
    import rdc_scaffold
    import tempfile, os
    with tempfile.TemporaryDirectory() as tmp:
        n = rdc_scaffold.build(tmp, dry_run=False, log=lambda x: None)
        results.append(f'  ✓ rdc_scaffold ({n} dirs created)')
except Exception as e:
    results.append(f'  ✗ rdc_scaffold: {e}')

# PyQt6 (headless — import only)
try:
    from PyQt6.QtWidgets import QApplication
    results.append('  ✓ PyQt6 import OK (display required to launch UI)')
except Exception as e:
    results.append(f'  ✗ PyQt6: {e}')

print()
for r in results:
    print(r)
print()
"
echo "[OK] Smoke tests complete."

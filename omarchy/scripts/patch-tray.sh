#!/usr/bin/env bash
# Merge the tray plugin's duplicate Component.onCompleted handlers.
# Usage: ./patch-tray.sh [path/to/Tray.qml]
# Requires Python 3. Refuses unknown implementations rather than guessing.
set -euo pipefail

if [[ ${1:-} == --help || ${1:-} == -h ]]; then
  echo 'Usage: patch-tray.sh [path/to/Tray.qml]'
  exit 0
fi
(( $# <= 1 )) || { echo 'Expected at most one target path.' >&2; exit 1; }
command -v python3 >/dev/null || { echo 'Required command missing: python3' >&2; exit 1; }
target=${1:-$HOME/.config/omarchy/plugins/io.github.tyrichards.tray/Tray.qml}

python3 - "$target" <<'PY'
import os
from pathlib import Path
import re
import stat
import sys
import tempfile

path = Path(sys.argv[1])
if path.is_symlink() or not path.is_file():
    sys.exit(f'Expected an existing regular file, not a symlink: {path}')

original = path.read_bytes()
text = original.decode('utf-8')
old = '''  Component.onCompleted: {
    root.stableLayoutConfig = root.bar ? root.bar.layoutConfig : null
    root.resolveWidgetRegistry()
  }
'''
new = '''  Component.onCompleted: {
    root.stableLayoutConfig = root.bar ? root.bar.layoutConfig : null
    root.resolveWidgetRegistry()
    Qt.callLater(root.reconcileHostedPlugins)
  }
'''
duplicate = '  Component.onCompleted: Qt.callLater(reconcileHostedPlugins)\n'
# Count only root-level handlers; nested delegates have their own handlers.
handlers = len(re.findall(r'^  Component\.onCompleted\s*:', text, re.MULTILINE))

if text.count(new) == 1 and duplicate not in text and handlers == 1:
    print(f'Tray patch already present: {path}')
    sys.exit(0)
if text.count(old) != 1 or text.count(duplicate) != 1 or handlers != 2:
    sys.exit(f'Unexpected tray implementation; review upstream before patching: {path}')

patched = text.replace(old, new, 1).replace(duplicate, '', 1)
# Stage alongside the original, preserve permissions, then replace atomically.
fd, temporary = tempfile.mkstemp(prefix='.tray-patch.', dir=path.parent)
try:
    with os.fdopen(fd, 'wb') as output:
        output.write(patched.encode('utf-8'))
        os.fchmod(output.fileno(), stat.S_IMODE(path.stat().st_mode))
    if path.read_bytes() != original:
        sys.exit('Tray changed during patching; refusing to overwrite it.')
    os.replace(temporary, path)
finally:
    if os.path.exists(temporary):
        os.unlink(temporary)
print(f'Applied tray patch: {path}')
PY

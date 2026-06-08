#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
README="$ROOT/README.md"

python3 - "$README" <<'PY'
from pathlib import Path
import sys
text=Path(sys.argv[1]).read_text()
required_sections=[
    '## Primary quickstart',
    '## Commands',
    '## Metadata and ownership',
    '## Migration from the older project-local model',
    '## Advanced options',
]
for section in required_sections:
    assert section in text, f'missing {section}'
quick=text.index('## Primary quickstart')
advanced=text.index('## Advanced options')
commands=text.index('## Commands')
assert quick < commands < advanced, 'primary flow must come before commands and advanced options'
primary_block=text[quick:commands]
assert primary_block.count('agent-ws init') == 1, 'primary quickstart should have one init command'
assert 'bootstrap.sh | bash' not in primary_block, 'primary quickstart should not present legacy bootstrap'
assert './bin/agent-workspace' not in text, 'README should not recommend project-local CLI copies'
assert 'Initialized projects receive a local template cache' not in text, 'README should not describe new project-local template caches'
PY
printf 'README structure: ok\n'

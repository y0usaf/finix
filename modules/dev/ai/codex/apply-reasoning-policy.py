"""Reconcile only Codex's root reasoning setting, preserving other config."""
import os
from pathlib import Path
import re
import stat
import sys
import tempfile
import tomllib


def apply(path):
    path = Path(path).expanduser().resolve()
    text = path.read_text() if path.exists() else ''
    before = tomllib.loads(text)
    # Only replace a root-level key, never a setting in a TOML table.
    header = re.search(r'^\s*\[', text, flags=re.MULTILINE)
    end = header.start() if header else len(text)
    root, rest = text[:end], text[end:]
    pattern = r'^(?:model_reasoning_effort|"model_reasoning_effort"|\'model_reasoning_effort\')\s*=.*$'
    root, count = re.subn(pattern, 'model_reasoning_effort = "low"', root, flags=re.MULTILINE)
    if not count:
        root = 'model_reasoning_effort = "low"\n' + root
    result = root + rest
    expected = {**before, 'model_reasoning_effort': 'low'}
    if tomllib.loads(result) != expected:
        raise ValueError('Refusing to change unrelated Codex settings')
    if result == text:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    mode = stat.S_IMODE(path.stat().st_mode) if path.exists() else 0o600
    fd, tmp = tempfile.mkstemp(dir=path.parent, prefix='.reasoning-policy-')
    try:
        with os.fdopen(fd, 'w') as stream:
            stream.write(result)
            os.fchmod(stream.fileno(), mode)
        os.replace(tmp, path)
    finally:
        if os.path.exists(tmp):
            os.unlink(tmp)
    assert tomllib.loads(path.read_text()) == expected


if __name__ == '__main__':
    apply(sys.argv[1])

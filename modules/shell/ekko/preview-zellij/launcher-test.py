"""Launch the packaged preview in a sized PTY and stop only its private daemon."""
import fcntl
import os
from pathlib import Path
import pty
import re
import select
import shutil
import json
import subprocess
import struct
import sys
import termios
import time

launcher, runtime, shell, *options = sys.argv[1:]
keep = bool(options)
master, slave = pty.openpty()
fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack('HHHH', 24, 80, 640, 384))
env = dict(os.environ)
env.pop('EKKO_CONFIG', None)
process = subprocess.Popen([launcher, *(['--keep-session'] if keep else []), shell, '-c', 'printf PREVIEW-LAUNCH-OK; read answer'],
                           stdin=slave, stdout=slave, stderr=slave, env=env,
                           start_new_session=True)
os.close(slave)
data = bytearray()
private = None
try:
    deadline = time.monotonic() + 10
    while time.monotonic() < deadline and b'PREVIEW-LAUNCH-OK' not in data:
        if select.select([master], [], [], .1)[0]:
            data.extend(os.read(master, 65536))
    match = re.search(rb'Private preview config: (.+)/config/init.lisp\r?\n', data)
    assert match, bytes(data)
    private = Path(os.fsdecode(match[1]))
    assert b'PREVIEW-LAUNCH-OK' in data, bytes(data)
    assert private.name.startswith('finix-ekko-zellij.')
    session_env = dict(env, XDG_RUNTIME_DIR=str(private))
    if keep:
        before = json.loads(subprocess.check_output([runtime, 'inspect', 'preview'], env=session_env))
        subprocess.run([runtime, 'command', '--session', 'preview', 'session-detach'],
                       env=session_env, capture_output=True, timeout=5, check=True)
        process.wait(timeout=5)
        assert process.returncode == 0 and private.exists()
        after = json.loads(subprocess.check_output([runtime, 'inspect', 'preview'], env=session_env))
        assert [p['pid'] for p in before['panes']] == [p['pid'] for p in after['panes']]
    stopped = subprocess.run([runtime, 'stop', 'preview'],
                             env=dict(env, XDG_RUNTIME_DIR=str(private)),
                             capture_output=True, timeout=5)
    assert stopped.returncode == 0, stopped.stderr
    process.wait(timeout=5)
    assert process.returncode == 0
    if keep:
        shutil.rmtree(private)
    assert not private.exists(), private
finally:
    if process.poll() is None:
        process.terminate()
        process.wait(timeout=5)
    os.close(master)
    if private and private.exists():
        subprocess.run([runtime, 'stop', 'preview'], env=dict(env, XDG_RUNTIME_DIR=str(private)),
                       capture_output=True, timeout=5)
        shutil.rmtree(private)
print('Packaged preview launches in 80x24 PTY and removes its private runtime on exit')

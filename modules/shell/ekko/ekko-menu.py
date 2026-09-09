"""Managed menu through the real client, daemon, worker and application PTYs."""
import fcntl
import json
import os
from pathlib import Path
import pty
import select
import signal
import struct
import subprocess
import sys
import tempfile
import termios
import time
import tty

if sys.argv[1] == '--child':
    tty.setraw(0, termios.TCSANOW)
    log = Path(sys.argv[2])
    log.touch()
    os.write(1, b''.join(f'history {i:03d}\r\n'.encode() for i in range(100)))
    with log.open('ab', buffering=0) as output:
        while True:
            data = os.read(0, 65536)
            output.write(data)
    sys.exit()

binary, source = sys.argv[1:]
with tempfile.TemporaryDirectory(prefix='finix-ekko-menu-') as directory:
    root = Path(directory)
    config = root / 'init.lisp'
    config.write_bytes(Path(source).read_bytes())
    log = root / 'input'
    env = dict(os.environ, XDG_RUNTIME_DIR=directory, EKKO_CONFIG=str(config),
               TERM='xterm-256color', SHELL='/bin/sh')
    env.pop('EKKO_SESSION_NAME', None)
    master, slave = pty.openpty()
    def size(cols, rows):
        fcntl.ioctl(master, termios.TIOCSWINSZ, struct.pack('HHHH', rows, cols, cols*8, rows*16))
        if 'process' in globals():
            os.kill(process.pid, signal.SIGWINCH)
    size(80, 24)
    process = subprocess.Popen([binary, 'run', '--session', 'menu', sys.executable,
                                __file__, '--child', str(log)], env=env,
                               stdin=slave, stdout=slave, stderr=slave, start_new_session=True)
    os.close(slave)
    output = bytearray()
    def pump():
        while select.select([master], [], [], .01)[0]:
            try:
                output.extend(os.read(master, 65536))
            except OSError:
                break
    def cli(*args):
        result = subprocess.run([binary, *args], env=env, capture_output=True, timeout=5)
        assert result.returncode == 0, (args, result.stderr)
        return result.stdout
    def inspect():
        return json.loads(cli('inspect', 'menu'))
    def wait(predicate):
        deadline = time.monotonic()+5
        while time.monotonic() < deadline:
            pump()
            if predicate():
                return
            time.sleep(.02)
        raise AssertionError((inspect(), bytes(output[-1000:])))
    def send(data, mode=None):
        os.write(master, data)
        if mode:
            wait(lambda: inspect()['mode'] == mode)
    def spans():
        return [span for owner in inspect()['decorations'] if owner['owner'] == 'finix'
                for span in owner['spans']]
    try:
        wait(lambda: log.exists())
        cli('config', 'check')
        wait(lambda: inspect()['mode'] == 'normal' and bool(spans()))
        initial_pid = inspect()['panes'][0]['pid']
        send(b'plain\x1b[A\xce\xbb')
        wait(lambda: log.read_bytes() == b'plain\x1b[A\xce\xbb')
        baseline = log.read_bytes()
        send(b'\x02', 'menu')
        wait(lambda: len(spans()) > 2)
        assert b'Commands' in output and log.read_bytes() == baseline
        send(b'?')
        pump()
        assert log.read_bytes() == baseline
        send(b'\r', 'panes')
        send(b'\x1b', 'menu')
        send(b'P', 'panes')
        send(b'\x1b', 'menu')
        send(b'\x1b', 'normal')
        send(b'\x02\x02', 'normal')
        wait(lambda: log.read_bytes() == baseline+b'\x02')
        send(b'\x07', 'locked')
        wait(lambda: any('LOCKED' in s['text'] for s in spans()))
        literal = b'\x02\x10[abc\x1b[A'
        send(literal)
        wait(lambda: log.read_bytes() == baseline+b'\x02'+literal)
        send(b'\x07', 'normal')
        send(b'\x10', 'panes')
        send(b'v', 'normal')
        wait(lambda: len(inspect()['panes']) == 2)
        send(b'\x02h', 'normal')
        wait(lambda: len(inspect()['panes']) == 3)
        send(b'\x10' + b'1', 'normal')
        wait(lambda: json.loads(cli('status', 'menu'))['focus'] == 1)
        send(b'\x02z', 'normal')
        wait(lambda: inspect()['zoom'])
        send(b'\x02z', 'normal')
        wait(lambda: not inspect()['zoom'])
        send(b'\x02[', 'normal')
        wait(lambda: 'Copy:' in inspect()['chrome-status']['text'])
        send(b'/history 042\r')
        wait(lambda: 'Search:' not in inspect()['chrome-status']['text'])
        send(b' \r')
        wait(lambda: b'history 042' in cli('buffer', 'menu'))
        send(b'q')
        wait(lambda: 'Copy:' not in inspect()['chrome-status']['text'])
        send(b'\x02[')
        wait(lambda: 'Copy:' in inspect()['chrome-status']['text'])
        send(b'\x07', 'locked')
        assert not json.loads(cli('status', 'menu'))['panes'][0]['copy_mode']
        send(b'\x07', 'normal')
        before = log.read_bytes()
        send(b'\x02]')
        wait(lambda: len(log.read_bytes()) > len(before))
        send(b'\x10', 'panes')
        send(b'\x1b[B'*12)
        wait(lambda: bool(inspect()['component-state']))
        for cols, rows in [(20, 8), (5, 4), (80, 24)]:
            size(cols, rows)
            wait(lambda: inspect()['viewport']['cols'] == cols and inspect()['viewport']['rows'] == rows)
            wait(lambda: all(0 <= s['y'] < rows and len(s['text']) <= cols for s in spans()))
            assert not inspect()['disabled-hooks']
        send(b'\x1b', 'menu')
        send(b'\x1b', 'normal')
        wait(lambda: len(spans()) == 1)
        assert inspect()['panes'][0]['pid'] == initial_pid
        send(b'\x10' + b'3x')  # focus action dismisses; x is ordinary app input
        wait(lambda: inspect()['mode'] == 'normal')
        send(b'\x10x', 'normal')
        wait(lambda: len(inspect()['panes']) == 2)
        generation = inspect()['generation']
        send(b'\x02r', 'normal')
        wait(lambda: inspect()['generation'] > generation)
        assert not inspect()['error'] and not inspect()['disabled-hooks']
        config.write_text('(error "intentional menu reload test")')
        failed = subprocess.run([binary, 'config', 'reload', 'menu'], env=env, capture_output=True, timeout=5)
        assert failed.returncode != 0
        wait(lambda: any('intentional menu reload test' in s['text'] for s in spans()))
        assert inspect()['mode'] == 'normal' and inspect()['panes'][0]['pid'] == initial_pid
        config.write_bytes(Path(source).read_bytes())
        cli('config', 'reload', 'menu')
        wait(lambda: not inspect()['error'])
        # Unmount from an open submenu: only Finix-owned mode/state/chrome vanish.
        send(b'\x10', 'panes')
        config.write_text('(in-package #:cl-user)\n')
        cli('config', 'reload', 'menu')
        wait(lambda: not any(o['owner'] == 'finix' for o in inspect()['decorations']))
        assert not inspect()['component-state'] and inspect()['mode'] is None
        assert inspect()['panes'][0]['pid'] == initial_pid
        assert any(o['owner'] == 'defaults' for o in inspect()['decorations'])
        config.write_bytes(Path(source).read_bytes())
        cli('config', 'reload', 'menu')
        wait(lambda: inspect()['mode'] == 'normal' and len(spans()) == 1)
        print(json.dumps({'status': 'pass', 'checks': ['real-client', 'leader', 'submenu', 'escape',
              'literal-prefix', 'locked-forwarding', 'split', 'focus', 'zoom', 'copy-search',
              'paste', 'small-viewport', 'dismiss', 'close', 'reload', 'owner-cleanup']}))
    finally:
        subprocess.run([binary, 'stop', 'menu'], env=env, capture_output=True, timeout=5)
        if process.poll() is None:
            process.wait(timeout=5)
        os.close(master)

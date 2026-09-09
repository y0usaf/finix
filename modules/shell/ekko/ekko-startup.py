"""Exercise the rendered Finix autostart fragment in Bash and rush on real PTYs."""
import fcntl
import json
import os
from pathlib import Path
import pty
import select
import struct
import subprocess
import sys
import tempfile
import termios
import time

rc, config, binary, *shells = sys.argv[1:]
source = Path(rc).read_text()
start = source.rfind('if [ -z "${EKKO_SESSION_NAME:-}" ]')
assert start >= 0, "Ekko startup is missing from the rendered interactive rc"
with tempfile.TemporaryDirectory(prefix="finix-ekko-test-") as directory:
    root = Path(directory)
    startup = root / "startup.sh"
    startup.write_text(source[start:])
    home = root / "home"
    (home / ".config/rush").mkdir(parents=True)
    inner = 'printf "INNER_SESSION=%s\\n" "$EKKO_SESSION_NAME"\n. "' + str(startup) + '"\n'
    (home / ".bashrc").write_text(inner)
    (home / ".config/rush/config.rush").write_text(inner)
    for shell in shells:
        env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home / ".config"),
                   XDG_RUNTIME_DIR=directory, EKKO_CONFIG=config, TERM="xterm-256color", SHELL=shell)
        for key in ("EKKO_SESSION_NAME", "SSH_CONNECTION", "TMUX", "STY"):
            env.pop(key, None)
        # Guarded shells and non-terminal invocations must remain usable.
        for key in ("EKKO_SESSION_NAME", "SSH_CONNECTION", "TMUX", "STY", "TERM", None):
            guarded = env.copy()
            if key:
                guarded[key] = "linux" if key == "TERM" else "already-inside"
            args = [shell, "-c", f'. "{startup}"; printf GUARD_OK']
            if key:
                guard_master, guard_slave = pty.openpty()
                try:
                    p = subprocess.run(args, env=guarded, stdin=guard_slave, stdout=guard_slave,
                                       stderr=subprocess.PIPE, timeout=5)
                    captured = os.read(guard_master, 4096)
                finally:
                    os.close(guard_master)
                    os.close(guard_slave)
            else:
                p = subprocess.run(args, env=guarded, capture_output=True, timeout=5)
                captured = p.stdout
            assert p.returncode == 0 and captured == b"GUARD_OK", (shell, key, p.stderr)
        master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 100, 800, 480))
        process = subprocess.Popen([shell, "-c", f'. "{startup}"'], env=env,
                                   stdin=slave, stdout=slave, stderr=slave, start_new_session=True)
        os.close(slave)
        output = bytearray()
        name = None
        try:
            deadline = time.monotonic() + 8
            while time.monotonic() < deadline:
                if select.select([master], [], [], .02)[0]:
                    output.extend(os.read(master, 65536))
                sockets = list((root / "ekko-v2").glob("*.sock"))
                if sockets and b"INNER_SESSION=terminal-" in output:
                    name = sockets[0].stem
                    break
            assert name, (shell, bytes(output[-2000:]))
            def cli(*args):
                return subprocess.check_output([binary, *args], env=env, timeout=5)
            state = json.loads(cli("status", name))
            assert state["attached"] and len(state["panes"]) == 1 and state["panes"][0]["exit_code"] is None
            cli("split", "--session", name, "columns")
            deadline = time.monotonic() + 1
            while time.monotonic() < deadline:
                if select.select([master], [], [], .02)[0]:
                    output.extend(os.read(master, 65536))
            state = json.loads(cli("status", name))
            assert len(state["panes"]) == 2 and all(p["exit_code"] is None for p in state["panes"])
            assert len(list((root / "ekko-v2").glob("*.sock"))) == 1, "recursive multiplexer startup"
            cli("stop", name)
            process.wait(timeout=4)
            assert process.returncode == 0
        finally:
            if name:
                subprocess.run([binary, "stop", name], env=env, capture_output=True, timeout=5)
            if process.poll() is None:
                process.kill()
                process.wait()
            os.close(master)
        print(json.dumps({"shell": shell, "status": "pass", "checks": ["autostart", "nested-guard", "split", "stop"]}))

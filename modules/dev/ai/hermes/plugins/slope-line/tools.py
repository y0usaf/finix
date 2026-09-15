"""The ``line_task`` handler: start a detached ``line`` run, wait on its trail lock, read its stop record.

Stdlib only, no relative imports (the tests load this file standalone). Every path returns a JSON
string — errors included — because a tool handler must never raise into dispatch. The child
environment is the parent's, unchanged: ``line`` reads its endpoint and the name of its key variable
from ``~/.config/slope/config.json``, so there is one source of truth and the plugin never sets
``SLOPE_API_KEY`` (line's highest-precedence override). The only addition is an opt-in escape hatch:
when the variable named by ``api_key_env`` is absent from the parent environment, a key read from
``api_key_file`` is injected under that one name. A key is never placed on the command line, in a
log, or in a result.
"""

from __future__ import annotations

import fcntl
import json
import os
import shutil
import subprocess
import time
import uuid
from pathlib import Path

# The returned `report` is truncated to this many characters (256 KiB — "a few hundred KB"); the
# result then carries report_truncated: true. Nothing else in a result is capped.
REPORT_CAP = 262144
DEFAULT_WAIT_SECONDS = 600
MAX_WAIT_SECONDS = 1800
# Cadence of the non-blocking lock probe; also the sleep when the run holds the lock.
LOCK_POLL_SECONDS = 0.2
# A starting call only reads config and forks, so this is generous.
START_TIMEOUT_SECONDS = 60
DEFAULT_LINE_BIN = "line"
DEFAULT_API_KEY_ENV = "AI_GATEWAY_API_KEY"
DEFAULT_API_KEY_FILE = "/home/y0usaf/Tokens/AI_GATEWAY_API_KEY.txt"
STOP_STATUSES = ("done", "suspended", "error")


def _dump(payload: dict) -> str:
    return json.dumps(payload)


def _fail(message: str) -> str:
    return _dump({"error": message})


def resolve_line(line_bin: str):
    """Absolute path of an executable *line_bin*, or None. A bare name is looked up on PATH."""
    if os.sep in line_bin:
        return line_bin if os.path.isfile(line_bin) and os.access(line_bin, os.X_OK) else None
    return shutil.which(line_bin)


def child_env(env_name: str, key_file: str) -> dict:
    """The parent environment, plus ``$<env_name>`` when the parent lacks it and *key_file* holds a key.

    The default is pass-through: ``line``'s config names both the endpoint and the key variable, so an
    already-set ``$<env_name>`` is the operator's, not ours. The one escape hatch is for a config
    whose variable the environment does not carry — then the trimmed key file is injected under that
    single named variable, and only that one. Nothing readable means nothing injected: line reports
    its own ``$<name> is not set``.
    """
    env = dict(os.environ)
    if not env_name or env.get(env_name, "").strip():
        return env
    try:
        key = Path(key_file).read_text().strip()
    except OSError:
        return env
    if key:
        env[env_name] = key
    return env


def compose_task(goal: str, context=None) -> str:
    """The goal, then — when there is context — a blank line, the literal ``Context:``, and the context."""
    if not context:
        return goal
    return f"{goal}\n\nContext:\n{context}"


def parse_handle(stdout: str) -> dict:
    """The six ``key value`` lines a starting call prints, as a dict."""
    handle = {}
    for line in stdout.splitlines():
        if line.strip():
            key, _, value = line.partition(" ")
            handle[key.strip()] = value.strip()
    return handle


def read_last(steps: str):
    """Last JSON record of a steps trail, or None while the trail is absent or empty.

    A malformed record raises ``ValueError`` — the caller turns it into an error result.
    """
    try:
        text = Path(steps).read_text()
    except FileNotFoundError:
        return None
    lines = [line for line in text.splitlines() if line.strip()]
    return json.loads(lines[-1]) if lines else None


def _pid_alive(pid) -> bool:
    try:
        os.kill(int(pid), 0)
    except ProcessLookupError:
        return False
    except (PermissionError, ValueError, TypeError, OverflowError):
        return True
    return True


def wait_for_stop(steps: str, pid, wait_seconds: float):
    """Wait until the run's trail holds a stop record, or the deadline passes.

    Returns ``(status, note)``: the stop status with an empty note, ``("timeout", "")`` when the
    deadline passed first, or ``("error", note)`` when the run's lock is free and its pid is gone
    without ever writing a stop record.

    The probe is a non-blocking ``LOCK_EX|LOCK_NB`` retry loop rather than a blocking ``lockf`` in
    a worker thread: one straight-line loop needs no thread lifecycle, so a cancelled or
    abandoned tool call cannot strand a thread holding the lock fd, and the wait stays bounded by
    *wait_seconds* without a signal alarm.
    """
    deadline = time.monotonic() + wait_seconds
    lock_path = steps + ".lock"
    while True:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            return ("timeout", "")
        try:
            # mode "w" is O_CREAT: the lock file may lag the handle.
            with open(lock_path, "w") as fh:
                try:
                    fcntl.lockf(fh, fcntl.LOCK_EX | fcntl.LOCK_NB)
                except OSError:
                    # Held by the run: it is alive, so wait again.
                    time.sleep(min(LOCK_POLL_SECONDS, remaining))
                    continue
                fcntl.lockf(fh, fcntl.LOCK_UN)
        except OSError as exc:
            raise ValueError(f"cannot open the lock file {lock_path}: {exc}")
        # We held the lock: the run has exited (or has not taken it yet).
        record = read_last(steps)
        status = (record or {}).get("status", "")
        if status in STOP_STATUSES:
            return (status, "")
        if not _pid_alive(pid):
            return ("error", f"line run {pid} ended without writing a stop record to {steps}")
        time.sleep(min(LOCK_POLL_SECONDS, remaining))


def runs_root(state_dir: str) -> Path:
    """Trails root: the ``state_dir`` setting, else ``<HERMES_HOME>/plugin-data/slope-line/runs``."""
    if state_dir:
        return Path(state_dir).expanduser()
    from plugins.plugin_storage import plugin_data_dir

    return plugin_data_dir("slope-line") / "runs"


def _setting(ctx, key: str, default: str) -> str:
    """One plugin setting, falling back to *default* when unset, empty, or unreadable."""
    if ctx is None:
        return default
    try:
        value = ctx.get_config(key, default)
    except Exception:
        return default
    return default if value is None or value == "" else str(value)


def settings(ctx) -> dict:
    """The plugin's settings, resolved with their defaults.

    ``line_model`` rather than ``model``: ``ctx.get_config`` rejects the reserved roots
    ``model``/``plugins``/``security``/``settings``.
    """
    return {
        "line_bin": _setting(ctx, "line_bin", DEFAULT_LINE_BIN),
        "api_key_env": _setting(ctx, "api_key_env", DEFAULT_API_KEY_ENV),
        "api_key_file": _setting(ctx, "api_key_file", DEFAULT_API_KEY_FILE),
        "state_dir": _setting(ctx, "state_dir", ""),
        "line_model": _setting(ctx, "line_model", ""),
        "base_url": _setting(ctx, "base_url", ""),
    }


def handle_line_task(args, ctx=None, **_kwargs) -> str:
    """Dispatch one ``line`` run and return its result as JSON. Never raises."""
    try:
        return _dispatch(args, ctx)
    except Exception as exc:  # a handler must not raise into dispatch
        return _fail(f"line_task failed: {type(exc).__name__}: {exc}")


def _dispatch(args, ctx) -> str:
    if not isinstance(args, dict):
        return _fail("line_task expects an object of arguments")
    goal = args.get("goal")
    if not isinstance(goal, str) or not goal.strip():
        return _fail("'goal' is required and must be a non-empty string")
    context = args.get("context")
    if context is not None and not isinstance(context, str):
        return _fail("'context' must be a string when given")
    dir_arg = args.get("dir")
    if dir_arg is not None and not isinstance(dir_arg, str):
        return _fail("'dir' must be a string when given")
    wait_seconds = args.get("wait_seconds", DEFAULT_WAIT_SECONDS)
    if isinstance(wait_seconds, bool) or not isinstance(wait_seconds, int):
        return _fail("'wait_seconds' must be an integer")
    wait_seconds = max(1, min(wait_seconds, MAX_WAIT_SECONDS))
    background = bool(args.get("background", False))

    workdir = dir_arg or os.getcwd()
    if not os.path.isdir(workdir):
        return _fail(f"working directory does not exist: {workdir}")

    config = settings(ctx)
    line_path = resolve_line(config["line_bin"])
    if line_path is None:
        return _fail(
            f"line_bin {config['line_bin']!r} is not an executable file; set "
            "plugins.entries.slope-line.settings.line_bin to the line binary"
        )
    try:
        root = runs_root(config["state_dir"])
        root.mkdir(parents=True, exist_ok=True)
    except OSError as exc:
        return _fail(f"cannot create the trails directory: {exc}")
    run_id = uuid.uuid4().hex
    steps = str(root / f"{run_id}.steps.jsonl")
    raw = str(root / f"{run_id}.raw.jsonl")

    command = [
        line_path, "--dir", workdir, "--step-file", steps, "--raw-file", raw,
        "--quiet", "--task", compose_task(goal, context),
    ]
    if config["line_model"]:
        command += ["--model", config["line_model"]]
    if config["base_url"]:
        command += ["--base-url", config["base_url"]]
    # The child inherits the parent environment, so line resolves its key the way its own config says
    # to. Only a named variable the parent lacks is filled in, from the key file, under that one name.
    env = child_env(config["api_key_env"], config["api_key_file"])
    try:
        started = subprocess.run(
            command, capture_output=True, text=True, env=env, timeout=START_TIMEOUT_SECONDS
        )
    except subprocess.TimeoutExpired:
        return _fail(f"line did not return a handle within {START_TIMEOUT_SECONDS}s")
    if started.returncode != 0:
        message = (started.stderr or "").strip() or (started.stdout or "").strip()
        return _fail(f"line exited {started.returncode}: {message or '(no message)'}")

    handle = parse_handle(started.stdout)
    if not handle.get("steps") or not handle.get("raw") or not handle.get("pid"):
        return _fail(f"line printed no usable handle: {started.stdout.strip()!r}")
    run = {
        "steps": handle.get("steps", steps),
        "raw": handle.get("raw", raw),
        "log": handle.get("log", raw + ".log"),
        "pid": handle["pid"],
        "line_bin": line_path,
        "dir": handle.get("dir", workdir),
    }
    check = {
        "status_command": f"{line_path} --status {run['steps']}",
        "log_command": f"{line_path} --log {run['steps']}",
    }
    if background:
        return _dump({
            **run, "status": "running", "background": True, **check,
            "pause_command": f"kill -INT {run['pid']}",
        })

    started_at = time.monotonic()
    status, note = wait_for_stop(run["steps"], run["pid"], wait_seconds)
    waited_ms = int((time.monotonic() - started_at) * 1000)
    record = read_last(run["steps"]) if status in STOP_STATUSES else None
    result = {**run, "status": status, "waited_ms": waited_ms}
    if status == "done":
        report = (record or {}).get("text", "")
        result["report"] = report[:REPORT_CAP]
        if len(report) > REPORT_CAP:
            result["report_truncated"] = True
            result["report_cap"] = REPORT_CAP
    elif status == "error":
        result["reason"] = note or (record or {}).get("reason", "") or "line recorded an error with no reason"
    else:
        result.update(check)
    return _dump(result)

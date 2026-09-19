"""cwd-command: an in-session ``/cwd`` slash command.

``/cwd`` prints the absolute working directory the terminal and file tools will
actually use and names where that value came from; ``/cwd <path>`` retargets the
running session. The retarget mirrors Hermes' own resume path
(``hermes_cli/cli_session_mixin.py::_restore_session_cwd``): process ``chdir``,
``TERMINAL_CWD``, plus the session cwd record and any live terminal backend that
the terminal tool caches. Nothing here touches the built-in command registry or
the agent loop; the command is registered through the plugin ``register(ctx)``
surface only.
"""

from __future__ import annotations

import logging
import os

logger = logging.getLogger(__name__)

# Previous directory for ``/cwd -``; process-local, costs nothing extra.
_previous = None

# ``TERMINAL_CWD`` values that mean "not configured" (mirrors tools/file_tools_paths.py).
_SENTINELS = frozenset({"", ".", "./", "auto", "cwd"})


def _task_key() -> str:
    """The raw task id the terminal/file tools resolve a cwd against.

    The tools receive ``effective_task_id`` = the top-level agent's session key,
    and both ``get_session_cwd`` and ``resolve_task_overrides`` read that RAW key
    first -- for the local backend it does NOT collapse to ``"default"``. Keying
    the cwd record/override anywhere else leaves ``_resolve_command_cwd``
    preferring a stale per-session record, so the move silently fails. Use the
    live CLI's session id when present, else the gateway session key, else
    ``"default"``.
    """
    cli = _cli_ref()
    session_id = getattr(cli, "session_id", "") if cli is not None else ""
    if session_id:
        return str(session_id)
    try:
        from tools.terminal_tool import _current_session_key

        return _current_session_key() or "default"
    except Exception:
        return "default"


def _cli_ref():
    """The live interactive-CLI object, or None in gateway/headless mode."""
    try:
        from hermes_cli.plugins import get_plugin_manager

        return get_plugin_manager()._cli_ref
    except Exception:
        return None


def _terminal_cwd_env() -> str:
    """Scope-aware ``TERMINAL_CWD`` (falls back to the process env outside a scope)."""
    try:
        from agent.runtime_cwd import scope_terminal_cwd

        return (scope_terminal_cwd() or "").strip()
    except Exception:
        return os.environ.get("TERMINAL_CWD", "").strip()


def _session_cwd():
    """Recorded session/override cwd for this task key, or None."""
    key = _task_key()
    try:
        from tools.terminal_tool import get_session_cwd

        recorded = get_session_cwd(key)
    except Exception:
        recorded = None
    if recorded:
        return recorded
    try:
        from tools.terminal_tool import resolve_task_overrides

        override = (resolve_task_overrides(key) or {}).get("cwd")
    except Exception:
        override = None
    return override if isinstance(override, str) and override.strip() else None


def _live_backend_cwd():
    """cwd of the cached terminal environment, when one has been created."""
    try:
        from tools import terminal_tool as tt

        key = tt._resolve_container_task_id(tt._current_session_key() or "")
        with tt._env_lock:
            env = tt._active_environments.get(key) or tt._active_environments.get("default")
        cwd = getattr(env, "cwd", None) if env is not None else None
        return cwd if isinstance(cwd, str) and cwd.strip() else None
    except Exception:
        return None


def _effective():
    """``(absolute path, source label)`` the tools will resolve against.

    Mirrors ``tools/file_tools_paths._authoritative_workspace_root``:
    session/override record, then ``TERMINAL_CWD``, then the process cwd.
    """
    recorded = _session_cwd()
    if recorded:
        return os.path.abspath(os.path.expanduser(recorded)), "session"
    env = _terminal_cwd_env()
    if env and env not in _SENTINELS:
        return os.path.abspath(os.path.expanduser(env)), "process (TERMINAL_CWD)"
    try:
        return os.path.abspath(os.getcwd()), "process (os.getcwd)"
    except OSError:
        return os.path.expanduser("~"), "fallback (~)"


def _persist_session_cwd(new: str) -> None:
    """Write the new cwd to the session row so /resume lands here. Best-effort."""
    cli = _cli_ref()
    db = getattr(cli, "_session_db", None)
    sid = getattr(cli, "session_id", None)
    if db is None or not sid:
        return
    try:
        db.update_session_cwd(sid, new)
    except Exception:
        logger.warning("cwd-command: could not persist session cwd", exc_info=True)


def _retarget(new: str) -> None:
    """Move process cwd, TERMINAL_CWD, the session record and the live backend to *new*.

    ``register_task_env_overrides`` is the terminal tool's own cwd-override entry
    point: it records the session cwd *and* updates the cached environment's
    ``cwd`` (the local backend snapshots cwd at construction, so the env var alone
    would not retarget an already-created shell).
    """
    os.chdir(new)
    os.environ["TERMINAL_CWD"] = new
    try:
        from tools.terminal_tool import register_task_env_overrides

        register_task_env_overrides(_task_key(), {"cwd": new})
    except Exception:
        logger.warning("cwd-command: could not register terminal cwd override", exc_info=True)
    _persist_session_cwd(new)


def _resolve_target(raw: str) -> str:
    expanded = os.path.expanduser(raw)
    if not os.path.isabs(expanded):
        expanded = os.path.join(os.getcwd(), expanded)
    return os.path.realpath(expanded)


def _handle(raw_args: str) -> str:
    global _previous
    raw = (raw_args or "").strip()

    if not raw:
        path, source = _effective()
        lines = [f"{path}  (source: {source})"]
        backend = _live_backend_cwd()
        if backend and os.path.realpath(backend) != os.path.realpath(path):
            lines.append(f"shell backend cwd: {backend}")
        return "\n".join(lines)

    if _cli_ref() is None:
        return "[x] /cwd cannot change the directory here (no interactive CLI session); no change made."

    if raw == "-":
        if _previous is None:
            return "[x] No previous directory recorded; cwd unchanged."
        target = _previous
    else:
        target = _resolve_target(raw)

    if not os.path.isdir(target):
        return f"[x] Not a directory: {target}  (cwd unchanged: {os.getcwd()})"

    old = os.getcwd()
    try:
        _retarget(target)
    except OSError as exc:
        return f"[x] Could not change to {target}: {exc}  (cwd unchanged: {old})"

    _previous = old
    return (
        f"-> cwd: {target}\n"
        f"   was: {old}\n"
        "   moved: process cwd + TERMINAL_CWD + session record + live terminal backend\n"
        "   note: the execution-environment block already built into the system prompt\n"
        "   still shows the old directory; it is not rewritten mid-conversation, so the\n"
        "   prompt cache stays valid."
    )


def register(ctx) -> None:
    """Register ``/cwd``; the name collides with no built-in command."""
    ctx.register_command(
        "cwd",
        handler=_handle,
        description="Show the working directory the shell/file tools use, or change it for this session.",
        args_hint="[path|-]",
    )

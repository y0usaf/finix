"""jev-tool-gate: a jev-judged, append-only refusal gate for tool calls.

The cache-safe "chrono-break": a wrong call is answered with a directive-shaped *tool result*
(``{"action": "block", "message": ...}`` -> Hermes writes it as the result of the call), never with a
rewrite of an earlier message. Nothing in the transcript is edited, so the request prefix stays
byte-identical and the provider's prefix cache keeps hitting.

Two hooks, no core change:

- ``pre_llm_call`` -- records the current turn's task text (the user message) for the session and
  returns ``None`` (injects nothing). The judgement needs to know what the turn is *for*.
- ``pre_tool_call`` -- for one mutating tool call, builds a small state (``task``, ``call``,
  ``recent_calls``), asks jev exactly one ``choice`` question, and blocks when jev's pick is a
  refusal at or above ``threshold``. A *pick* is used, not a ``noul``: jev's noul is uncalibrated.

Fail-open at every step: any doubt, exception, timeout, non-zero exit, unparseable output, sentinel
pick, unrecorded task, or missing binary returns ``None`` and the call runs untouched. Bounded three
ways so the gate can never wedge a turn: a free deterministic gate (tool allowlist + read-only
command skip), a per-turn block strike limit, and a per-session jev-call cap. ``pre_tool_call`` is
Hermes's one fail-closed hook, so the jev round trip is hard-killed at the request timeout plus a
small grace.
"""

from __future__ import annotations

import json
import logging
import re
import subprocess
import threading

logger = logging.getLogger(__name__)

DEFAULT_JEV_BIN = "/home/y0usaf/dev/developing/jev/jev-cli/result/bin/jev"
DEFAULT_TIMEOUT_MS = 2500
GRACE_SECONDS = 0.5
DEFAULT_TOOLS = ["terminal", "write_file", "patch", "execute_code"]
DEFAULT_THRESHOLD = 0.60
DEFAULT_MAX_BLOCKS_PER_TURN = 2
DEFAULT_MAX_CALLS_PER_SESSION = 40
DEFAULT_TASK_CHARS = 1500
DEFAULT_CALL_CHARS = 1200
DEFAULT_RECENT_CALLS = 6

PROCEED = "proceed"
REFUSALS = {
    "refuse-destructive": "it removes, overwrites or corrupts data this task does not require",
    "refuse-off-task": "it does not serve the task",
    "refuse-repeat": "it repeats a call that already ran in this session",
}

# A terminal command whose first word is one of these reads and does not change anything; it is not
# worth a jev round trip. Deliberately a first-word allowlist (not a parser): a false negative here
# only means the gate stays shut, and the allowlist is configurable.
_READ_ONLY_COMMANDS = frozenset(
    "ls cat bat head tail less more grep rg egrep fgrep find fd locate pwd echo printf which type "
    "command wc tree stat file du df date env printenv whoami id uname hostname readlink realpath "
    "basename dirname cmp diff sort uniq cut tr jq yq".split()
)

_STATE_LOCK = threading.Lock()
_STATE: dict = {}  # session_id -> {"task", "turn_id", "blocks", "calls", "recent"}


def _session_state(session_id: str) -> dict:
    with _STATE_LOCK:
        return _STATE.setdefault(
            str(session_id or ""),
            {"task": "", "turn_id": "", "blocks": 0, "calls": 0, "recent": []},
        )


def _setting(ctx, key: str, default, cast):
    """One plugin setting, falling back to *default* when unset, empty, or unreadable."""
    try:
        value = ctx.get_config(key, default)
    except Exception:
        return default
    if value is None or value == "":
        return default
    try:
        return cast(value)
    except Exception:
        return default


def _as_bool(value) -> bool:
    if isinstance(value, str):
        return value.strip().lower() in ("1", "true", "yes", "on")
    return bool(value)


def _as_int(value) -> int:
    return int(value)


def _as_float(value) -> float:
    return float(value)


def _as_list(value) -> list:
    if isinstance(value, str):
        return [part.strip() for part in value.replace(",", " ").split() if part.strip()]
    return [str(v) for v in value]


def _text_of(user_message) -> str:
    """Flatten a str or multimodal (list of parts) user message to text; '' when there is none."""
    if isinstance(user_message, str):
        return user_message
    if isinstance(user_message, list):
        parts = [p.get("text", "") for p in user_message
                 if isinstance(p, dict) and isinstance(p.get("text"), str)]
        return " ".join(parts)
    return ""


def _clip(text: str, limit: int) -> str:
    text = str(text or "")
    return text if len(text) <= limit else text[:limit] + " …[truncated]"


def _call_json(tool_name: str, args) -> str:
    """The call as one compact JSON object; unparseable args are stringified, never dropped."""
    try:
        payload = json.dumps({"tool": tool_name, "args": args}, ensure_ascii=False, sort_keys=True)
    except Exception:
        payload = json.dumps({"tool": tool_name, "args": str(args)}, ensure_ascii=False)
    return _clip(payload, DEFAULT_CALL_CHARS)


def _first_word(command: str) -> str:
    match = re.match(r"\s*([A-Za-z0-9_.\-/]+)", str(command or ""))
    return (match.group(1) if match else "").rsplit("/", 1)[-1].lower()


def _worth_judging(tool_name: str, args, tools: list) -> bool:
    """The free gate: an allowlisted tool, and a terminal command that is not plainly read-only."""
    if tool_name not in tools:
        return False
    if tool_name == "terminal":
        command = args.get("command") if isinstance(args, dict) else None
        if not isinstance(command, str) or not command.strip():
            return False
        if _first_word(command) in _READ_ONLY_COMMANDS:
            return False
    return True


def _ask_jev(jev_bin: str, document: dict, timeout_ms: int):
    """Run ``jev ask`` on the document; return ``(pick, probability)`` or ``(None, 0.0)``."""
    proc = subprocess.run(
        [jev_bin, "ask", "-", "--json", "--timeout", str(timeout_ms)],
        input=json.dumps(document),
        capture_output=True,
        text=True,
        timeout=timeout_ms / 1000.0 + GRACE_SECONDS,
    )
    if proc.returncode != 0:
        logger.debug("jev-tool-gate: jev exit %s: %s", proc.returncode, (proc.stderr or "").strip())
        return None, 0.0
    answer = (json.loads(proc.stdout).get("answers") or {}).get("verdict") or {}
    if answer.get("type") != "choice":
        return None, 0.0
    pick = answer.get("choice")
    probabilities = answer.get("probabilities")
    if not isinstance(pick, str) or not isinstance(probabilities, dict):
        return None, 0.0
    try:
        probability = float(probabilities.get(pick, 0.0))
    except Exception:
        probability = 0.0
    return pick, probability


def _document(task: str, tool_name: str, args, recent: list) -> dict:
    return {
        "state": {
            "gate_note": (
                "You are the decision gate for a coding agent's tool calls. `task` is what the user "
                "asked for. `call` is the tool call the model is about to make. `recent_calls` lists "
                "calls already made in this session, oldest first. Decide whether `call` should run."
            ),
            "task": task,
            "call": _call_json(tool_name, args),
            "recent_calls": "\n".join(recent) if recent else "(none)",
        },
        "questions": [{
            "id": "verdict",
            "type": "choice",
            "instructions": (
                "Which verdict applies to `call`? Choose exactly one option label: proceed if `call` "
                "is a reasonable next step for `task`; refuse-destructive if it removes, overwrites "
                "or corrupts data `task` does not require; refuse-off-task if it does not serve "
                "`task`; refuse-repeat if it repeats a call already listed in `recent_calls`."
            ),
            "options": (
                [{"name": PROCEED, "description": "the call is a reasonable, on-task next step"}]
                + [{"name": name, "description": why} for name, why in REFUSALS.items()]
            ),
        }],
    }


def _refusal_message(tool_name: str, pick: str, probability: float) -> str:
    return (
        f"REFUSED by jev-tool-gate: {tool_name} -> {pick} (p={probability:.2f}). Nothing ran. "
        f"{REFUSALS[pick]}. Reconsider the call against the task; if you still believe it is right, "
        f"make the call again with a `reason` that states why."
    )


def _on_pre_llm_call(ctx, **kwargs):
    """``pre_llm_call``: record the turn's task text; inject nothing (returns ``None`` always)."""
    try:
        session_id = str(kwargs.get("session_id") or "")
        turn_id = str(kwargs.get("turn_id") or "")
        message = _text_of(kwargs.get("user_message")).strip()
        state = _session_state(session_id)
        with _STATE_LOCK:
            if message:
                state["task"] = _clip(message, _setting(ctx, "task_chars", DEFAULT_TASK_CHARS, _as_int))
            # A new turn_id is a new user turn: the block strike limit is per turn.
            if turn_id and turn_id != state["turn_id"]:
                state["turn_id"] = turn_id
                state["blocks"] = 0
    except Exception:
        logger.debug("jev-tool-gate: pre_llm_call failed", exc_info=True)
    return None


def _on_pre_tool_call(ctx, **kwargs):
    """``pre_tool_call``: judge the call with jev and block with a directive, or return ``None``."""
    try:
        if not _setting(ctx, "enabled", True, _as_bool):
            return None
        tool_name = str(kwargs.get("tool_name") or "")
        args = kwargs.get("args")
        args = args if isinstance(args, dict) else {}
        tools = _setting(ctx, "tools", DEFAULT_TOOLS, _as_list)
        if not _worth_judging(tool_name, args, tools):
            return None

        session_id = str(kwargs.get("session_id") or "")
        state = _session_state(session_id)
        task = state["task"]
        if not task:
            return None  # no recorded task: nothing to judge the call against

        max_blocks = _setting(ctx, "max_blocks_per_turn", DEFAULT_MAX_BLOCKS_PER_TURN, _as_int)
        max_calls = _setting(ctx, "max_calls_per_session", DEFAULT_MAX_CALLS_PER_SESSION, _as_int)
        with _STATE_LOCK:
            if state["blocks"] >= max_blocks or state["calls"] >= max_calls:
                return None
            recent = list(state["recent"])
            state["calls"] += 1
            call = _call_json(tool_name, args)
            state["recent"].append(_clip(call, 200))
            del state["recent"][:-DEFAULT_RECENT_CALLS]

        threshold = _setting(ctx, "threshold", DEFAULT_THRESHOLD, _as_float)
        timeout_ms = _setting(ctx, "timeout_ms", DEFAULT_TIMEOUT_MS, _as_int)
        jev_bin = _setting(ctx, "jev_bin", DEFAULT_JEV_BIN, str)

        pick, probability = _ask_jev(jev_bin, _document(task, tool_name, args, recent), timeout_ms)
        if pick not in REFUSALS or probability < threshold:
            return None
        with _STATE_LOCK:
            state["blocks"] += 1
        message = _refusal_message(tool_name, pick, probability)
        logger.debug("jev-tool-gate: blocked %s", message)
        return {"action": "block", "message": message}
    except Exception:
        logger.debug("jev-tool-gate: gate/jev failed; letting the call run", exc_info=True)
        return None


def register(ctx) -> None:
    """Register the two hooks: task recording (``pre_llm_call``) and the gate (``pre_tool_call``)."""
    ctx.register_hook("pre_llm_call", lambda **kwargs: _on_pre_llm_call(ctx, **kwargs))
    ctx.register_hook("pre_tool_call", lambda **kwargs: _on_pre_tool_call(ctx, **kwargs))

"""jev-skill-router: a gated, fail-open, per-turn skill hint driven by the user's ``jev`` CLI.

Registers only ``pre_llm_call`` (no tool, no state that outlives the turn). Each turn it scores
the user message against the live skill catalogue with a free, deterministic token/idf overlap
gate. Only when the gate is non-trivial does it ask ``jev`` (document mode, one ``choice`` question
whose options are the candidate skill names plus a ``none-of-these`` sentinel) which single skill
to load, and returns one line for the user message. Anything else -- a sentinel pick, exception,
timeout, non-zero exit, unparseable output, or a missing binary -- returns ``None`` so the turn
proceeds untouched. No core changes; the CLI resolves its own key file, and no key is ever passed,
logged, or printed here.
"""

from __future__ import annotations

import json
import logging
import math
import re
import subprocess

logger = logging.getLogger(__name__)

DEFAULT_JEV_BIN = "/home/y0usaf/dev/developing/jev/jev-cli/result/bin/jev"
DEFAULT_TIMEOUT_MS = 2500
DEFAULT_MIN_CANDIDATES = 3
DEFAULT_MAX_CANDIDATES = 12
SENTINEL = "none-of-these"
# Hard kill is the request timeout plus this grace, so a wedged node process can never stall a turn.
GRACE_SECONDS = 0.5
_TOKEN_RE = re.compile(r"[a-z0-9]+")
_STOPWORDS = frozenset(
    "a an the this that these those and or but if then else of to in on at by for with from into "
    "over under is are was were be been being do does did it its as so than too very can should "
    "would could will just not no none any all some use using used when".split()
)
_GREETINGS = frozenset(
    "hi hello hey yo hiya thanks thank ty ok okay k yes yeah no nope bye goodbye cheers".split()
)


def _tokens(text) -> list:
    """Lowercase alphanumeric tokens, minus stopwords and one-character noise."""
    return [t for t in _TOKEN_RE.findall(str(text or "").lower())
            if t not in _STOPWORDS and len(t) > 1]


def _catalogue() -> list:
    """The live skill catalogue (name/description/category) via ``skills_list``; [] on any failure."""
    from tools.skills_tool import skills_list
    data = json.loads(skills_list())
    return data.get("skills", []) if isinstance(data, dict) else []


def _rank(message: str, skills: list) -> list:
    """Candidate skills with a positive idf-weighted token overlap against *message*, best first."""
    query = set(_tokens(message))
    if not query or not skills:
        return []
    docs = {}
    for s in skills:
        name = str(s.get("name") or "")
        docs[name] = (set(_tokens(name) + _tokens(s.get("description")) + _tokens(s.get("category"))),
                      str(s.get("description") or ""))
    total = len(docs)
    df = {}
    for tokens, _ in docs.values():
        for t in tokens:
            df[t] = df.get(t, 0) + 1

    def idf(t: str) -> float:
        n = df.get(t, 0)
        return math.log(1 + (total - n + 0.5) / (n + 0.5)) if n else 0.0

    scored = []
    for name, (tokens, description) in docs.items():
        score = sum(idf(t) for t in query if t in tokens)
        if score > 0:
            scored.append((score, name, description))
    scored.sort(key=lambda row: (-row[0], row[1]))
    return scored


def _text_of(user_message) -> str:
    """Flatten a str or multimodal (list of parts) user message to text; '' when there is none."""
    if isinstance(user_message, str):
        return user_message
    if isinstance(user_message, list):
        parts = [p.get("text", "") for p in user_message
                 if isinstance(p, dict) and isinstance(p.get("text"), str)]
        return " ".join(parts)
    return ""


def _ask_jev(jev_bin: str, document: dict, timeout_ms: int):
    """Run ``jev ask`` on the document and return a real pick, or None on anything unexpected."""
    proc = subprocess.run(
        [jev_bin, "ask", "-", "--json", "--timeout", str(timeout_ms)],
        input=json.dumps(document),
        capture_output=True,
        text=True,
        timeout=timeout_ms / 1000.0 + GRACE_SECONDS,
    )
    if proc.returncode != 0:
        logger.debug("jev-skill-router: jev exit %s: %s", proc.returncode, (proc.stderr or "").strip())
        return None
    answer = (json.loads(proc.stdout).get("answers") or {}).get("pick") or {}
    if answer.get("type") != "choice":
        return None
    pick = answer.get("choice")
    return pick if isinstance(pick, str) and pick != SENTINEL else None


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


def _on_pre_llm_call(ctx, **kwargs):
    """``pre_llm_call`` callback: a hint string, or None to inject nothing."""
    try:
        if not _setting(ctx, "enabled", True, _as_bool):
            return None
        message = _text_of(kwargs.get("user_message")).strip()
        if not message or message.lstrip().startswith("/"):
            return None
        if message.lower().rstrip("!.?") in _GREETINGS:
            return None

        min_candidates = _setting(ctx, "min_candidates", DEFAULT_MIN_CANDIDATES, _as_int)
        max_candidates = _setting(ctx, "max_candidates", DEFAULT_MAX_CANDIDATES, _as_int)
        timeout_ms = _setting(ctx, "timeout_ms", DEFAULT_TIMEOUT_MS, _as_int)
        jev_bin = _setting(ctx, "jev_bin", DEFAULT_JEV_BIN, str)

        candidates = _rank(message, _catalogue())
        # Non-trivial gate: several plausible skills (jev picks among them), or exactly one
        # unambiguous match (the live catalogue rarely yields 3 lexical matches for a message that
        # clearly names one skill, so a lone candidate must still reach jev to be confirmed).
        if not candidates or not (len(candidates) >= min_candidates or len(candidates) == 1):
            return None

        shortlist = candidates[:max(max_candidates, 1)]
        document = {
            "state": {
                "routing_note": (
                    "You are the skill router for a coding agent. skill_index lists the skills "
                    "currently offered to the model. Pick the one skill that should be loaded to "
                    "handle user_message, or none-of-these when no skill is relevant."
                ),
                "skill_index": "\n".join(f"{name} - {desc}" for _, name, desc in shortlist),
                "user_message": message,
            },
            "questions": [{
                "id": "pick",
                "type": "choice",
                "instructions": (
                    "Which single skill from `skill_index` should be loaded to handle "
                    "`user_message`? Choose exactly one option label; choose none-of-these if no "
                    "skill is relevant."
                ),
                "options": ([{"name": name, "description": desc} for _, name, desc in shortlist]
                            + [{"name": SENTINEL}]),
            }],
        }
        pick = _ask_jev(jev_bin, document, timeout_ms)
        for _, name, _desc in shortlist:
            if pick == name:
                hint = f"Likely skill for this turn (jev): {name} - load with skill_view('{name}')."
                logger.debug("jev-skill-router: hint -> %s", hint)
                return hint
        return None
    except Exception:
        logger.debug("jev-skill-router: gate/jev failed; injecting nothing", exc_info=True)
        return None


def register(ctx) -> None:
    """Register the single ``pre_llm_call`` hook; nothing else is provided."""
    ctx.register_hook("pre_llm_call", lambda **kwargs: _on_pre_llm_call(ctx, **kwargs))

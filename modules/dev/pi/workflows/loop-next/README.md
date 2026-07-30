# loop-next workflow

Loop a project's `/next` skill via
[pi-extensible-workflows](https://github.com/vekexasia/pi-extensible-workflows)
(vendored at `@extensions/vekexasia_pi-extensible-workflows/`) until `PLAN.md`
has no unchecked boxes.

Each iteration is one `agent()` call = one **fresh sub-agent context**, which
is exactly what the `next` skill assumes ("the previous session's context is
gone"). The main session's context never grows; the run is backgrounded.

The loop stops at:

1. **plan complete** — the worker greps `PLAN.md` and reports zero unchecked
   boxes (`openBoxes: 0`, enforced by `outputSchema`),
2. **uncommittable step** — tree/build broken before the step started; the
   run returns early with the step summaries,
3. the **iteration cap** — `maxSteps`, default 30, hard max 100,
4. the **run budget** if one was set at launch.

## Prerequisites

- Extension enabled in the system flake: `programs.pi.extensions.extensible-workflows = true;`
- Project has `PLAN.md` in its root with `- [ ]` checkbox items.
- A `next` skill exists for the project (`.pi/skills/next` or user skills) —
  sub-agents inherit session skills and are told to load it by name.
- Tree clean enough that step 1 can commit; unrelated WIP contaminates every
  step's commit.
- System flake places this directory into `~/.local/share/pi/agent/workflows/loop-next/`
  (`modules/dev/pi/workflows.nix`); the engine scans that root for `command.json`
  and registers `/loop-next`. Files here are the source of truth.

## Invoke

Slash command (no budget possible — cap is the only guard):

```
/loop-next            # 30 steps
/loop-next 10         # 10 steps
/loop-next '{ "maxSteps": 10 }'
```

Workflow tool (adds a token/cost backstop):

```json
{
  "name": "loop-next",
  "scriptPath": "/home/y0usaf/dev/pi-flake/workflows/loop-next/loop-next.js",
  "args": { "maxSteps": 30 },
  "budget": { "agentLaunches": { "hard": 35 }, "tokens": { "hard": 5000000 } }
}
```

Runs are backgrounded; completion arrives as a follow-up message. Control a
live run with `/workflow` (pause / resume / stop / status).

## Failure modes

- **Cap reached, boxes remain** → likely a stuck step (same item failing).
  Read the returned step summaries, fix the blocker manually, rerun.
- **Early stop, `committed: false`** → the summary says why the step could
  not commit.
- **`openBoxes` is worker-reported** (the worker runs the grep itself, and
  the schema forces a number). Verify after completion:
  `grep -c '\[ \]' PLAN.md`. A premature 0 is a prompt bug, not a finished
  plan.

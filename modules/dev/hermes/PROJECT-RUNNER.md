# Hermes project runner

`hermes-project` runs a bounded coding project with one planner, up to two
concurrent workers, and one reviewer. It uses existing Hermes profiles but starts
a **fresh conversation for every invocation**. It never sends work to Bot Chat.
It is an optional CLI alongside the desktop, not a replacement for normal chat.

```sh
hermes-project start --repo ~/my-project \
  --goal 'Implement the requested feature and its regression coverage' \
  --check 'python3 -m unittest discover -s tests'
```

Use `--goal-file /absolute/path/spec.md` for a detailed specification. Include
priorities, acceptance criteria, and scope constraints. Repeat `--check` for
multiple required checks. Commands are split into argv without shell evaluation;
if shell syntax is intentional, pass an explicit `bash -lc '...'` command.
Checks must be noninteractive, bounded, and leave the worktree clean.

The start command prints a run directory immediately. In another terminal:

```sh
hermes-project status ~/.hermes/project-runs/RUN_ID
hermes-project resume ~/.hermes/project-runs/RUN_ID
```

Ctrl-C/SIGTERM pauses the scheduler and stops active process groups. `resume`
continues from durable state. SIGKILL or runner crashes also terminate ordinary
child process groups via a Linux parent-death supervisor. Interrupted workers
are recorded as failed, their worktrees retained, and their failure is passed
to the next planner. Completed worker commits awaiting review are retained and
processed before new planning. A lock permits only one scheduler per run.

Run it in a terminal multiplexer or with an existing background-process tool
and completion notification if it should continue after closing the chat.
No daemon or automatic restart service is installed. `--prepare-only` creates
the run and private branch without starting agents. `status` is read-only and
does not acquire the scheduler lock.

## Workflow and result

1. Snapshot committed `HEAD` (or `--base REV`) onto
   `hermes-project/RUN_ID`; verify the baseline before calling a model.
2. The planner inspects that branch and emits at most two independent task
   contracts: instructions, allowed paths, and acceptance criteria.
3. Workers implement in separate detached worktrees. The runner validates
   structured handoffs and changed paths, then commits the changes locally.
4. Each commit is cherry-picked onto the latest private integration branch
   in another worktree. Required checks and an independent review must pass
   before the branch advances. Conflicts and rejected changes return to the
   planner as failed tasks; workers do not repair unrelated failures.
5. The planner receives task history, handoffs, and failures in a fresh context
   each round. A claimed complete goal receives final checks and a separate
   goal-completion review before the run is marked complete.

This initial version plans in small rounds: both workers finish before their
results are integrated and the next round starts. It does not implement
recursive planners or the article's large continuously replenished fleet.

The original checkout, its current branch, and uncommitted edits are preserved.
Uncommitted changes are **not included** in the starting snapshot. All automatic
integration is confined to the run's private branch. No push, PR publication,
merge into the original branch, deployment, or system activation is performed.
Inspect the finished result with:

```sh
git -C ~/my-project diff HEAD...hermes-project/RUN_ID
git -C ~/my-project log --oneline HEAD..hermes-project/RUN_ID
```

The run directory contains atomic `state.json`, timestamped `events.jsonl`,
each agent's exact prompt/transcript/JSON handoff under `attempts/`, verification
logs, and retained worktrees. These are local task records and may contain
project data. Nothing is automatically cleaned up. Remove worktrees with
`git worktree remove PATH` only after retaining any wanted results; remove the
private branch separately when it is no longer needed.

Each invocation also receives its own `attempts/NUMBER-ROLE/scratch` directory
as `TMPDIR`, with instructions to put temporary verification helpers there.

## Profiles and limits

Defaults use planner profile `default`, worker profile `worker`, and reviewer
profile `reviewer`. Override with `--planner-profile`, `--worker-profile`, and
`--reviewer-profile`. Model/provider selection remains in those profiles.
Only `terminal,file` toolsets are requested. The role contract forbids recursive
delegation, background jobs, messaging, and profile/memory changes.

| Option | Default | Scope |
| --- | ---: | --- |
| `--workers` | 2 | Maximum concurrent workers (1 or 2) |
| `--max-calls` | 16 | Total Hermes invocations, including planning and reviews |
| `--max-rounds` | 4 | Total planner invocations |
| `--max-turns` | 40 | Hermes tool-calling iterations per invocation |
| `--agent-seconds` | 600 | Hard wall-clock timeout per invocation |
| `--max-agent-seconds` | 9600 | Cumulative reserved agent-seconds across the run |
| `--check-seconds` | 300 | Hard timeout for each required check |

Invocation and runtime reservations are written **before spawn** and never
refunded on interruption. Resuming does not reset limits. These limits bound
activity, **not a dollar amount**: token usage and provider pricing vary, and
the chat CLI does not export authoritative per-invocation billing. Use provider
spend controls when an actual currency ceiling is required. Exhausted runs stop
with `budget_exhausted`; they never silently increase limits. Start a new run
from the retained integration branch if further work is wanted.

A worktree isolates Git edits, not filesystem or network permissions. Hermes
and verification commands run with the invoking user's access and existing
approval configuration; this is intended for trusted local repositories.
The scheduler checks scope and branch contents, but is not a security sandbox.
Processes that deliberately create new sessions can escape process-group
cleanup; workers are instructed not to start background work.

## Installation and verification

Finix includes the command in the Hermes system packages and exposes it as
`packages.SYSTEM.hermes-project`:

```sh
nix build path:.#hermes-project --no-link --no-write-lock-file
nix run path:.#hermes-project -- --help
```

The package check runs real Git/process integration tests with a deterministic
Hermes CLI fixture. It covers two-worker integration, unchanged original
checkouts, scope violations, malformed handoffs, review rejection, failed
checks, merge conflicts, budget persistence, exclusive ownership, interrupted
workers, parent death, and recovery on both sides of an integration-ref update.
These tests validate scheduling and recovery; they do not establish model
reliability on arbitrary goals.

For the current installation, the GC-rooted package is available immediately at
`~/.hermes/bin/hermes-project`; use that path in place of `hermes-project` in the
examples until the next normal Finix deployment adds the command to system PATH.

Requires Linux, Python 3.11+, Git, and the installed Hermes CLI supporting
`chat --query-file`, `--oneshot`, `--max-turns`, and `--run-budget`.
`--hermes /path/to/hermes` or `HERMES_PROJECT_HERMES` selects a specific CLI.

---
name: ship
description: >-
  Finish explicitly requested repository work end to end: inspect and split the current Git diff into logical commits, validate, commit and push, update the matching direct input in the user's downstream system flake, and activate it with nh os switch. Use when the user says "split the diff logically, commit and push, update flake, nh os switch", asks to ship completed work into their NixOS configuration, or invokes /skill:ship. Do not use for ordinary commit or push requests that omit the flake update and system switch.
compatibility: Requires git, Nix with flakes, nh, network access, and a downstream flake selected by --flake, NH_FLAKE, or ~/nixos.
metadata:
  author: y0usaf
  version: "1"
---

# Ship

Ship current repository into downstream system configuration.

## Execution contract

- Explicit invocation authorizes full workflow: commits, non-force pushes, one targeted flake-input update, and system activation.
- Work autonomously. Do not pause for plans or routine confirmation.
- Diagnose and repair recoverable failures, then continue from failed phase.
- Ask user only when required information or intent cannot be inferred safely: unresolved semantic conflict, credentials, no matching input, ambiguous matching inputs, or branch/input-ref mismatch requiring a policy choice.
- Never discard user work. No `reset --hard`, `clean`, destructive checkout/restore, force push, or blanket stash.
- Never update every flake input.
- Leave downstream `flake.lock` change uncommitted and unpushed.

Arguments may override defaults:

- `flake=<path>`: downstream flake; default `$NH_FLAKE`, then `~/nixos`
- `input=<name>`: direct flake input; default auto-detection from current repository remotes
- Any other text: extra task, validation, or commit guidance

## Helper

Resolve helper once and reuse absolute path:

```bash
helper="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/skills/ship/scripts/system-flake"
test -x "$helper"
```

Helper commands:

```bash
"$helper" resolve --source "$source" [--flake "$flake"] [--input "$input"]
"$helper" deploy  --source "$source" [--flake "$flake"] [--input "$input"]
"$helper" switch  [--flake "$flake"]
```

`resolve` matches source Git remotes against direct root inputs in downstream `flake.lock`. `deploy` verifies published input ref points at source `HEAD`, updates only that input, verifies locked revision equals `HEAD`, then runs `nh os switch` without allowing another lock update.

## Workflow

### 1. Pin source context

Before changing directories:

```bash
source="$(git rev-parse --show-toplevel)"
branch="$(git -C "$source" branch --show-current)"
head_before="$(git -C "$source" rev-parse HEAD)"
```

Require Git worktree and attached branch. Read repository instructions. Inspect:

```bash
git -C "$source" status --short --branch
git -C "$source" diff --stat
git -C "$source" diff
git -C "$source" diff --cached
git -C "$source" log -12 --oneline
```

Inspect untracked files directly. Detect unresolved merges, submodule changes, generated files, vendored output, and likely secrets.

Run helper `resolve` before commits. Save its JSON. This catches downstream mapping problems early and identifies matching remote plus declared input ref. If it fails, inspect source remotes and downstream `flake.nix`/`flake.lock`; retry with inferred `--input`. Ask only if still genuinely ambiguous or absent.

If source repository is downstream flake itself, skip input resolution/update and use `switch` after push.

### 2. Validate and partition

Treat all relevant current changes as scope. Exclude obvious secrets, credentials, caches, and accidental build output; do not delete excluded files.

Infer validation commands from repository docs, manifests, CI, and recent practice. Run focused checks first, then broad affordable checks. Fix failures caused by current work. Distinguish confirmed pre-existing failures from regressions.

Partition by intent and dependency:

- One coherent reason per commit.
- Keep implementation with its tests.
- Keep manifest and corresponding lockfile together.
- Keep required schema/migration with consumer when separating would break history.
- Separate unrelated refactors, docs, tooling, and behavior changes.
- Prefer each commit independently valid when practical.
- Do not manufacture tiny commits when one change is truly atomic.

Infer message style from recent history.

### 3. Commit each group

Stage explicit paths or hunks, never blind `git add .`/`git add -A`. Before every commit:

```bash
git -C "$source" diff --cached --stat
git -C "$source" diff --cached
git -C "$source" diff --cached --check
```

Verify staged diff matches one planned intent, then commit. If hooks modify files or fail, inspect, fix, restage, and retry. Do not bypass hooks unless repository policy explicitly requires it.

After final commit:

- Run relevant final validation.
- Ensure no intended tracked changes remain.
- Review resulting commit range and messages.
- Amend only newly created local commits when needed; never rewrite published history.

### 4. Push safely

Refresh `resolve` output after commits. Publish current `HEAD` without force.

- If branch has upstream, push normally.
- If no upstream, select matching writable remote from resolver output and set upstream.
- Ensure remote/ref consumed by flake input also receives `HEAD`. If normal upstream differs, push matching input remote too.
- For explicit input `ref`, publish to that ref only when branch/ref relationship is clear.
- On non-fast-forward rejection, fetch and inspect. Rebase/merge only when resolution is unambiguous; never force.

Do not continue to deployment until push succeeds.

### 5. Update one input and switch

Run:

```bash
"$helper" deploy --source "$source" [--flake "$flake"] [--input "$input"]
```

Helper guarantees:

1. Source has no uncommitted tracked changes.
2. Exactly one direct downstream input matches, unless explicitly selected.
3. Input is movable rather than pinned to another immutable revision.
4. Input's remote branch/tag/default branch resolves to source `HEAD`.
5. Only selected input is passed to `nix flake update`.
6. Updated lock node revision equals source `HEAD`.
7. `nh os switch` runs only after verification, with lock writes disabled during build.

Do not commit or push downstream lockfile.

### 6. Recover failures autonomously

- Resolver failure: inspect URL normalization, aliases, renamed repos, root input mapping, and explicit input name.
- Publication mismatch: inspect declared input ref and `git ls-remote`; push correct non-force ref when intent is clear.
- Lock mismatch: verify flake input URL/ref, remote visibility, and cache/fetch result. Never switch wrong revision.
- Nix evaluation/build/switch failure: inspect complete error, fix source or downstream config as appropriate, validate, and resume. If source changes, create another logical commit, push, then rerun `deploy`.
- Authentication or material branch/ref ambiguity: ask user with exact blocker and options.

## Completion

Report only useful facts:

- Commits created: short SHA + subject
- Push destination/ref
- Downstream input and old → new revision
- Validation results
- `nh os switch` result
- Any intentionally uncommitted downstream or excluded source files

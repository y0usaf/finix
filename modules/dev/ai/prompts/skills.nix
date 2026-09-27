{
  config,
  lib,
  pkgs,
  ...
}: let
  skills = {
    anti-slop = {
      "SKILL.md".text = ''
        ---
        name: anti-slop
        description: >-
          Language-agnostic anti-slop hygiene for code in any language (TypeScript,
          JavaScript, Rust, Go, Lua, Python). Rejects low-evidence patterns: stacked
          casts, silenced type contracts, reflective dispatch where a direct call works,
          ad-hoc type-checking mid-function, mocking over real seams, and casting without
          a stated invariant. Use whenever writing, reviewing, or refactoring code, and
          when "anti-slop", "slop", "low-evidence", "avoid unknown", "no unsafe casts",
          or "type hygiene" come up. A principles skill, not a linter; per-language
          enforcement lives in the actual linter (clippy, oxlint).
        ---

        # Anti-slop

        Slop is any pattern that gets the compiler to accept a thing by discarding or faking evidence instead of making the program honest. Fix the evidence, not the syntax. These moves reduce every typed-language slop rule to a habit you can carry into any language:

        ## Principles

        1. Keep values as narrow as they actually are. Don't widen at an assignment and re-narrow at the use site.
           - TS: no `const handlers: Record<string, Handler> = { start: startHandler }` (discards the known start key; prefer inference or `satisfies Record<string, Handler>`).
           - TS: no `const user = input as object as User;` — stacked casts are the first false step.
           - Rust: no `let x: Box<dyn Any> = concrete; ... x.downcast_ref::<Concrete>()`. Carry the concrete type.

        2. No dynamic dispatch when a typed call exists.
           - TS: no `Reflect.apply(fn, owner, args)` / `Reflect.get(owner, key)`.
           - Rust: no `Any::downcast_ref` or reflection when a named method works.
           - If you can name the function, call it and let the type checker hold the contract.

        3. Parse once, at the boundary; never type-check inside the body.
           - TS: no `typeof input === "string"` checks scattered through logic; parse `unknown` into a known type at the input edge (JSON boundary, HTTP body), then the rest is typed.
           - Rust: deserialize raw bytes / a `serde_json::Value` into a concrete struct at the boundary (serde derive). Let the parser hold the evidence, not ad-hoc `.as_str()` checks.
           - Dynamic languages too: validate input in one place and return a typed/slotted result; do not re-check shape deep in the call tree.

        4. A cast must state the invariant it proved. Every cast needs a SAFETY comment naming what earlier step made it sound.
           - TS: `// SAFETY: parseUserId validated the identifier before branding it.` above `const userId = value as UserId;`
           - Rust: same, above an unavoidable `as` (never bare `transmute`) and above a `#[allow(...)]` forcing a cast.

        5. Name the contract, not the shape of the container.
           - TS: no `function save(value: object)`, no `Record<string, unknown>` for a thing with real fields, no alias that merely hides `unknown` (`type ExternalValue = unknown`).
           - Rust: no `HashMap<String, Value>` surfacing everywhere; use `#[serde(deny_unknown_fields)]` where the schema is known.
           - Lua: one named table with a boundary validator, not a `{}` any caller shapes.

        6. Real seams over mocks. Test through the actual dependency boundary (a function argument, a trait impl, an interface, an injected client), not a mocking library that fabricates an isolated copy. TS: no `vi.mock("./user-store")`. Rust: inject the trait impl rather than swizzle global state.

        7. Don't smuggle shape into names. No `UserShape`, no `recordOfUsers`. Name it what it is: `User`, `Users`.

        8. No conditional-omission hacks.
           - TS: `...(timeout !== undefined ? { timeout } : {})` spread hacks are out; build the object honestly.

        9. `unknown`/`any`/`Box<dyn Any>` is a confession, not a contract. A loose return or param means the owner never decided what the boundary carries. Acceptable only as the single catch-and-narrow point at the edge, immediately narrowed.

        ## Boundary test
        Run on every interface: input arrives as `unknown` once at the edge, is parsed into a concrete type, and is fully typed from there. If an `unknown`/`Value`/`dyn Any` survives past the first two lines of a function, the slop is there — move the parse to the boundary.

        ## Shipping checklist
        Every one of these must pass before shipping a changeset:
        - Every cast/`downcast`/unwrap has a SAFETY comment naming what proved it.
        - No value widened then re-narrowed; `unknown` is parsed exactly once.
        - No reflective/dynamic dispatch where a plain typed call exists.
        - Every `unknown`/`Value`/`Any` is handled at a boundary, never mid-function.
        - No mock fattening a seam that could take a real argument.
        - Structs/dicts/trees built by constructors, not spread-omit or empty-grow hacks.
        - Nothing is named `…Shape` or ornament-shaped.

        The skill is judgement, not machinery. If clippy, oxlint, or the borrow checker already reject a form, do not reproduce it here — keep only what a human must weigh.
      '';
    };
    codebase-atlas = {
      "SKILL.md".text = ''
        ---
        name: codebase-atlas
        description: Turn a codebase into an interactive isometric architecture map written as a single self-contained HTML file, in the hatched drafting-paper style with hover descriptions, animated data-flow dots, go-inside drill-downs, and a step-by-step request trace. Use when the user says "make a codebase atlas", "make one for my codebase", "turn this repo into a visual diagram", "isometric codebase map", "visual map of the architecture", or points at a FleetingBits-style isometric codebase screenshot and asks for the same. Also use to update or extend an existing atlas. Not for single mechanism diagrams inside a prose answer (draw inline SVG), Mermaid/flowchart requests, or UI mockups of the product itself.
        ---

        # Codebase Atlas

        Produce a single self-contained HTML page (no external deps, CSP-safe) that maps a repository as
        an isometric city: blocks sized by real line counts, edges carrying animated data dots, a left
        structure rail, and a right WHAT IT DOES / HOW IT'S BUILT panel. Write it as a single HTML file.

        ## Step 1: Inventory the repo (facts, not guesses)

        Spawn an Explore agent (very thorough) asking for a structured inventory:

        - 15-35 major subsystems, each with: short name, directory/key files, 1-2 plain-English sentences
        for a non-expert, rough size (files or LOC), and what it talks to (directed edges with what flows).
        - Overall request flow, databases/storage, headline stats (total LOC, routers/routes, feature
        counts, test files, deployed services).
        - Ask it to correct your assumed subsystem list, and to distinguish deployed **services** from
        code-level **roles**

        Every number shown in the atlas must come from this scan. Never invent counts.

        ## Step 2: Build from the template engine

        Copy `references/atlas-template.html` (the finished CordComputer atlas) into the session scratchpad
        and keep the engine; replace only the DATA section near the top of the script:

        - `STRUCTURES`: id, 2-char code, name, group, loc label, grid pos `gx,gy`, footprint `w,d`,
        height `h` (scale by LOC), `what`, `how`, `talks[]`, optional `children[]` (code, name, h, what)
        for go-inside views, optional `slab:true` for flat storage blocks.
        - `EDGES`: `{f, t, flow:1}` for animated main-path edges, `dashed:1` for advisory/CI edges,
        `pay` names what travels (shown when hovering a dot), optional `via:[[gx,gy]...]` waypoints.
        - `EXTERNALS`: off-map labels with dashed leaders (LLM providers, SaaS APIs, uploads).
        - `TRACE`: 10-14 `[structId, sentence]` steps walking one canonical request end to end.
        - Topbar stats, sidebar `GROUPS`, and the two overview essays (`OVERVIEW_WHAT`, `OVERVIEW_HOW`).

        Layout rules that make it read well:

        - Iso projection is `x=(gx-gy)*26, y=(gx+gy)*14.3 - h*16`. Keep block footprints disjoint;
        painter order sorts by `gx+gy` so nothing needs z-hacks.
        - Cluster by zone: browser surfaces top, API below them, agent right, ingestion left, core domain
        center, compute below it, storage slabs bottom row, CI in a corner.
        - Default edge routing is an L-elbow; add `via` waypoints only when a line would cut through an
        unrelated cluster. Lines hidden under blocks are acceptable.
        - Biggest subsystem = tallest block. Storage = flat slabs. The eye should find the core domain
        in the middle.

        ## Step 3: Verify headlessly before finishing

        The template has a URL-hash debug hook. Screenshot at 1800x1000 with
        `npx --yes playwright screenshot` against `file://...` for at least: the default view, one
        `#inside=<id>` view, and `#trace=7`. Look for label collisions, external labels clipping,
        orphaned blocks, and edges slicing through clusters. Fix, reshoot, then write the final HTML file
        (favicon 🗺️, keep it stable across rewrites).

        ## Step 4: Share-safety pass (always, before the user posts it)

        The atlas may leave the company. Keep code structure (module names, LOC, stack); scrub anything
        that describes live infrastructure: concrete cloud service/queue names, public endpoint paths,
        API-key prefixes or formats, where credentials are stored, project IDs, resource shapes. Grep the
        final file for the company's cloud naming prefix, `@`, `secret`, key prefixes, and mount paths.
        Remind the user the HTML file stays private until they share it from the page menu.
      '';
    };
    ship = {
      "SKILL.md".text = ''
        ---
        name: ship
        description: >-
          Finish explicitly requested repository work end to end: inspect and split the current Git diff into logical commits, validate, commit and push, update the matching direct input in the user's downstream system flake, and activate it with nh os switch. Use when the user says "split the diff logically, commit and push, update flake, nh os switch", asks to ship completed work into their NixOS configuration, or invokes /skill:ship. Do not use for ordinary commit or push requests that omit the flake update and system switch.
        compatibility: Requires git, Nix with flakes, nh, network access, and a downstream flake selected by --flake, NH_FLAKE, or ~/finix.
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

        - `flake=<path>`: downstream flake; default `$NH_FLAKE`, then `~/finix`
        - `input=<name>`: direct flake input; default auto-detection from current repository remotes
        - Any other text: extra task, validation, or commit guidance

        ## Helper

        The helper lives beside this file at `scripts/system-flake`. Resolve it from this skill's own directory — the `location` path shown for `ship` in the skills listing — and reuse that absolute path:

        ```bash
        helper="$(dirname <path to this SKILL.md>)/scripts/system-flake"
        test -x "$helper"
        ```

        Do not `readlink -f` the SKILL.md path first: it is a symlink into the Nix store, and that store path contains only the file itself, not the `scripts/` sibling. Do not fall back to a guessed path if `test -x` fails — report the failure instead.

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
      '';
      "scripts/system-flake" = {
        executable = true;
        text = ''
          #!${lib.getExe pkgs.python3}
          ${builtins.readFile ./ship-system-flake.py}
        '';
      };
    };
  };
in {
  manzil.users."${config.user.name}".files = lib.mkMerge (lib.concatLists (lib.mapAttrsToList (name: files:
    map (root: lib.mapAttrs' (rel: spec: lib.nameValuePair "${root}/${name}/${rel}" spec) files) [
      ".fx/skills"
      ".pi/agent/skills"
      ".config/phi/skills"
      ".prime/agent/skills"
      ".reasonix/skills"
      ".omp/agent/skills"
    ])
  skills));
}

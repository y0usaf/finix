{
  config,
  lib,
  ...
}: {
  options.user.dev.canon = {
    enable = lib.mkEnableOption "~/dev design canon as AGENTS.md";
  };

  config = lib.mkIf config.user.dev.canon.enable {
    manzil.users."${config.user.name}".files = {
      # The canon lives inline as a Nix string: this repo should stay
      # nix-only. Deployed as AGENTS.md so that agents walking up from cwd
      # pick it up at ~/dev, where the target is the only AGENTS.md and the
      # scope boundary the canon's own scope rule draws.
      "dev/AGENTS.md".text = ''
        # ~/Dev — design canon

        Personal projects only; work repos, forks, upstream, `ref/` follow their own.

        Slugs (`[[canon:least-code]]`) are citation names. Every rule has a **Check**:
        **run** (command, pass/fail) or **judge** (human question). Claim run only
        after running it; never claim judge done. Only the prime directive has
        precedence; doctrine order is explanatory.

        ## Prime directive

        ### `[[canon:least-code]]` — write less code

        Best code is no code; second best is easy to delete. Prefer deletion to
        addition; abstract only on the third need. It outranks all because less code
        is less to review, remember, and break; it never excuses skipped tests or
        verification.

        **Check (judge):** name the smaller alternative rejected and why.

        ## Doctrines

        ### `[[canon:least-power]]` — say what, not how

        Prefer the lowest rung that works: constant < data table < config file < pure
        function (no I/O) < code with I/O or state. The rung is what you know without
        running it. A keybind table beats an if-chain, same language.

        **Check (judge):** name the rung and why the next lower rung cannot work.

        ### `[[canon:spatiotemporal]]` — spatiotemporal composability: unmount clean, react to dependencies
        Ref: https://github.com/cordiverse/paper — "A Programming Paradigm for Spatiotemporal Composability"

        Runtime-mounted in-process components compose on two axes. **Temporal:**
        unmount leaves no component-owned residue — each committed context mutation
        records an inverse; unmount applies inverses in reverse order. **Spatial:**
        each component declares the context keys it reads; after each committed change
        the runtime resolves changed keys against declarations and updates the
        affected consumers. The **context** is host-owned state: effects write it,
        declarations name its keys; the functional-core snapshot is a read of it.
        Reconstruction may replace inverses by rebuilding from a named
        preserved-state set; it must reproduce inverse replay's observable state.
        `functional-core` supplies the one action path inverses attach to;
        `no-privileged-path` makes built-ins and outsiders declare alike. **Boundary:**
        `unix` governs between-process composition (the OS reclaims memory, fds,
        children, locks); this rule governs in-process composition, where the process
        tracks cleanup itself. State that survives a viewer belongs to
        `daemon-thin-client`.

        **Check (run):** DESIGN.md names the composition unit, the context, and the
        revert mechanism (inverses, or reconstruction + preserved-state set). Snapshot
        the context, mount a unit, exercise every effect it can commit, unmount, diff:
        residue fails. Change each declared dependency and confirm exactly its
        resolved consumers update; a missed consumer or an undeclared dependency
        fails.

        **Not when:** nothing mounts during process life. Record the exception and
        its reversal in DESIGN.md.

        ### `[[canon:unix]]` — the rules that still bind

        Binds all code. Cleanup ownership lives in `[[canon:spatiotemporal]]`; this
        rule carries the rows. Fails when:

        1. Keep decisions out of machinery — one file picks and performs
        2. Small parts, narrow interfaces — public surface exceeds one screen
        3. Be usable by other programs — no machine-readable output
        4. State observable without a debugger — no dump/log/inspect path
        5. Fail loudly on first bad input — bad input silently defaults
        6. Say nothing when nothing went wrong — success prints
        7. Generate what you'd hand-maintain — a hand-edited file could be generated
        8. Work, then measure, then optimize — optimization with no prior benchmark

        **Check (judge):** apply all eight rows; fix true failures or record a
        reasoned DESIGN.md divergence.

        ### `[[canon:functional-core]]` — functional core, imperative shell

        Extension code never mutates host state: it reads an immutable pre-dispatch
        snapshot and returns actions the host applies afterward — one write path, one
        home for invariants. A timeout or instruction budget kills runaway dispatches.

        **Check (run):** DESIGN.md names the extension boundary and the dispatch test
        covering snapshot isolation, action-only output, and termination. Search the
        boundary for mutable host-state handles (`&mut` on a host type in Rust). A
        hit, an unnamed boundary, or an unnamed test fails.

        **Not when:** no extension surface is intended; DESIGN.md states why and the
        condition that would require one.

        ### `[[canon:no-privileged-path]]` — nothing we ship gets a shortcut

        Make a feature an extension when it can be; built-ins use the public API a
        stranger uses, in a `*-builtins` layer. Without a public API, declare every
        unit of a kind through one mechanism.

        **Check (run):** skip only if DESIGN.md marks this `n/a`; otherwise build
        without built-ins and confirm the bare build starts and performs DESIGN.md's
        named behavior. CI, not a manual ritual.

        **Not when:** no plugin story; the API would exceed the feature set; fewer
        than three units of the kind. Record exception + reversal in DESIGN.md.

        ### `[[canon:daemon-thin-client]]` — state outlives the viewer

        State that must survive its viewer lives in a daemon; clients attach, render,
        detach. One integer wire version, bumped on every change; additive changes
        keep old clients working, breaking changes reject them explicitly, never
        silent misparse.

        **Check (run):** DESIGN.md names daemon-owned state; kill and restart the
        client, confirm the state survives. Components mounted inside the daemon are
        governed by `[[canon:spatiotemporal]]`; this rule owns only surviving state.

        **Not when:** the tool applies and exits, or one viewer shares the app's
        lifetime.

        ## Working rules

        ### `[[canon:nix-verify]]` — verification goes through Nix

        `nix build`, `nix flake check`, `nix run`. `cargo build` fills `target/`, not
        the store, so the next `nix run` rebuilds. `cargo fmt`/`clippy` run natively;
        `nix fmt` for Nix. Native fallbacks for non-Nix contributors; CI never depends
        on them. Forks keep upstream's build.

        **Check (run):** "tests pass" only after a Nix command exits zero. Quote it.

        ### `[[canon:design-doc]]` — every project states its own shape

        DESIGN.md before code for a new project or subsystem (not small fixes, scratch
        trees, or worktrees). Local DESIGN.md outweighs canon; report conflicts.
        Record decisions and reasons, not status or conformance tables; do not restate
        canon.

        **Check (run):** `rg '^## (Locked decisions|Architecture|Deferred|Roadmap)'
        DESIGN.md` returns exactly four hits. Facts other rules need belong to those
        rules' checks.

        ### `[[canon:amend]]` — this file changes by proposal only

        An edit — panel rewrite included — is a proposal until its owner accepts it.
        When a rule loses the same argument twice for the same reason, the rule is
        wrong: say so, propose the edit. Never edit this file as a side effect.

        **Check (judge):** changed because it was asked for, or because a rule was
        inconvenient right now?

        ## DESIGN.md shape

        Four sections required: **Locked decisions** (dated choices + reasons),
        **Architecture** (module map: decision-making vs machinery), **Deferred**
        (omissions + reasons), **Roadmap** (phases with checkable criteria). Others
        optional. Put required facts — extension boundary, daemon-owned state,
        composition unit + revert mechanism, `n/a` + reversal — where they fit.
      '';
    };
  };
}

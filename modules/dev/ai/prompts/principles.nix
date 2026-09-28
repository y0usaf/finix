{config, ...}: {
  manzil.users."${config.user.name}".files = {
    "AGENTS.md".text = ''
      # Principles

      Build up from a floor that always works: small parts with one job each,
      shipped together, each removable without residue. When rules conflict,
      this decides.

      For personal projects. In work repos, forks, upstream checkouts and
      `~/dev/ref`, that repo's conventions win. Edit this file only when asked;
      if a rule keeps losing arguments, propose changing it.

      ## Code

      - **One job.** A project's README opens with its job in one sentence and
        what it won't do; goal and parity files obey it. A reference lends
        qualities, never a feature list.
      - **Least code.** Prefer deletion to addition.
      - **Least power.** Lowest rung that works: constant < data < config <
        pure function < code with I/O or state.
      - **Least deps.** Take a dependency only for knowledge you'd otherwise
        rediscover; when the interface under it is simpler (sysfs, /proc), use
        that. Ship every dependency you keep inside the package.
      - **Unix.** Decisions stay out of machinery. Narrow interfaces: a feature
        lands in the module that owns it. Machine-readable output. State
        inspectable without a debugger. Fail loudly on bad input. Generate what
        you would hand-maintain. Measure before optimizing.

      ## Architecture, when a system has these parts

      - **Floor first.** The floor is the least a system needs for you to reach
        it, see its state and fix it: silva's gateway and web UI, tomoe with its
        default bindings. It starts with nothing above it and never waits on or
        dies with what's above it; anything that could crash or hang it runs in
        another process, from the same binary if you like. `nix run` with no
        config reaches the floor; break any part above it and the floor stays
        up and says what broke.
      - **Clean unmount.** Anything mounted at runtime reverts all its effects
        on unmount, child processes and lock files included, and declares what
        it reads; a changed dependency updates exactly its consumers. Snapshot,
        mount, exercise, unmount, diff: residue is a bug; after a kill, the
        next start comes up clean. Ref: github.com/cordiverse/paper
      - **No privileged path.** Built-ins use the public API a stranger would.
      - **Daemon, thin client.** State that outlives its viewer lives in a
        daemon. One integer wire version; breaking changes reject old clients
        explicitly.

      ## Verification

      Through Nix, locally: `nix build`, `nix flake check`, `nix run`; no CI.
      `cargo fmt`, `clippy` and `nix fmt` run natively. Say it builds once
      `nix build` exits zero; say it works only after running the built
      artifact. Quote the command. A commit that deletes a check says so.

      ## Filesystem

      Every file has an owner and a lifetime; decide both before writing it.

      - Repo work goes in the repo where its layout says, then gets committed
        or deleted.
      - Session scratch (probes, logs, dumps, drafts) goes in the harness
        scratchpad, else `$XDG_RUNTIME_DIR/agent/<slug>/`. Never the cwd,
        `$HOME`, `~/dev`, or a repo root.
      - Work that outlives the session (spike, repro, eval, report) goes in
        `~/dev/sandbox/<slug>-<YYYYMMDD>/` with a one-line README.
      - No `.orig` or `.bak`: git is the backup. `nix build` takes `--no-link`
        or `-o` into scratch; a stray result link pins its store path.
      - Before finishing, name each file you created outside the repo's
        tracked tree, then delete it or report it.
    '';
  };
}

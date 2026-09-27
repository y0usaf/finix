{
  config,
  lib,
  ...
}: {
  options.user.dev.prompts.principles = {
    enable = lib.mkEnableOption "design principles as ~/AGENTS.md";
  };

  config = lib.mkIf config.user.dev.prompts.principles.enable {
    manzil.users."${config.user.name}".files = {
      "AGENTS.md".text = ''
        # Principles

        For personal projects. In work repos, forks, upstream checkouts and
        `~/dev/ref`, that repo's conventions win. Edit this file only when asked;
        if a rule keeps losing arguments, propose changing it.

        ## Code

        - **One job.** A project states its job in one sentence and what it won't
          do; goal and parity files obey it. A reference lends qualities, never a
          feature list. Ship parts together, but each could run as its own process.
        - **Least code.** Prefer deletion to addition. Abstract on the third need.
        - **Least power.** Lowest rung that works: constant < data < config <
          pure function < code with I/O or state.
        - **Least deps.** Take a dependency only for knowledge you'd otherwise
          rediscover; when the interface under it is simpler (sysfs, /proc, one
          D-Bus call), use that. Ship every dependency you keep inside the package.
        - **Unix.** Decisions stay out of machinery. Narrow interfaces: a feature
          lands in the module that owns it. Machine-readable output. State
          inspectable without a debugger. Fail loudly on bad input; stay silent
          on success. Generate what you would hand-maintain. Measure before
          optimizing.

        ## Architecture, when a system has these parts

        The first three govern parts sharing one process; between processes the
        kernel already reverts and isolates.

        - **Clean unmount.** Anything mounted at runtime reverts all its effects
          on unmount and declares what it reads; a changed dependency updates
          exactly its consumers. Snapshot, mount, exercise, unmount, diff:
          residue is a bug. Ref: github.com/cordiverse/paper
        - **Functional core.** Extensions read an immutable snapshot and return
          actions the host applies. No mutable host handles; a budget kills
          runaway dispatch.
        - **No privileged path.** Built-ins use the public API a stranger would;
          the build without them still starts.
        - **Daemon, thin client.** State that outlives its viewer lives in a
          daemon. One integer wire version; breaking changes reject old clients
          explicitly.

        ## Verification

        Through Nix, locally: `nix build`, `nix flake check`, `nix run`; no CI.
        Cargo builds do not land in the store. `cargo fmt`, `clippy` and `nix fmt`
        run natively. Forks keep upstream's build. Say it builds once `nix build`
        exits zero; say it works only after running the built artifact. Quote the
        command. A commit that deletes a check says so.

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
  };
}

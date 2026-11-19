{config, ...}: {
  user.files."AGENTS.md".text = ''
    # Principles
    Personal projects only; in work repos, forks, upstream checkouts, and `~/dev/ref`, repo conventions win. Edit only when asked.

    ## Design
    - **Floor first & clean unmount**: minimal always-working floor (tomoe default binds; `nix run` reaches it) isolated from crashes/hangs above it; runtime mounts declare reads and revert all effects/procs/locks/sockets with zero residue (`github.com/cordiverse/paper`); no privileged built-in path.
    - **One job, least code/power/deps**: prefer deletion, abstract on 3rd need, constant < data < config < pure fn < IO/state, discover/config over hardcoding, take deps only when simpler interfaces (sysfs, `/proc`) don't suffice and package them in.
    - **Deterministic first**: state machines/rules for lifecycle, cleanup, routing, retries; LLM calls only for judgment.
    - **Small engine, rich surface**: minimal tools/flags in engine; polish in UI. Persistent state lives in a daemon with thin clients and an integer wire version.
    - **Unix**: narrow interfaces, machine-readable output, fail loudly at boundaries, generate rather than hand-maintain, measure before optimizing.

    ## Verification
    - Nix locally (`nix build --no-link` or `-o` into scratch, `nix flake check`, `nix run`; no CI); `cargo fmt`/`clippy`/`nix fmt` natively.
    - Verify running built artifacts in private instances (own socket/bus, `env -i`), never the live session. Quote the command; note deleted checks in commit.

    ## Filesystem
    - Session scratch: harness scratchpad or `$XDG_RUNTIME_DIR/agent/<slug>/` (never cwd, `$HOME`, `~/dev`, or repo root).
    - Persistent spikes: `~/dev/sandbox/<slug>-<YYYYMMDD>/` with a 1-line README.
    - No `.orig`/`.bak` files. Delete or report any file created outside the repo before finishing.
  '';
}

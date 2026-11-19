{
  config,
  lib,
  ...
}: let
  inherit (config.user.dev.prompts) host;
  portable = ''
    # Principles
    Personal projects only (work repos, forks, upstream, `~/dev/ref` follow repo conventions). Edit only when asked.

    - **Floor first & clean unmount**: minimal always-working floor (`nix run` reaches it) isolated from crashes/hangs above; runtime mounts declare reads and revert all effects/procs/locks/sockets with zero residue (`github.com/cordiverse/paper`); no privileged built-in path.
    - **Least code/power/deps**: prefer deletion; constant < data < config < pure fn < IO/state; discover/config over hardcoding; avoid deps when sysfs/`/proc` suffices; ship kept deps inside the package.
    - **Deterministic first**: state machines/rules for lifecycle, cleanup, routing, retries; LLM calls only for judgment. Small engine, polish in UI; persistent state in a daemon with thin clients and integer wire version.
    - **Verify locally via Nix**: `nix build --no-link` (or `-o` into scratch), `nix flake check`, `nix run` (no CI); test built artifacts in private instances (own socket/bus, `env -i`), never the live session. Quote the command; note deleted checks in commit.
    - **Filesystem**: scratch in harness scratchpad or `$XDG_RUNTIME_DIR/agent/<slug>/` (never cwd, `$HOME`, `~/dev`, repo root); persistent spikes in `~/dev/sandbox/<slug>-<YYYYMMDD>/` with 1-line README; no `.orig`/`.bak`; delete or report files created outside repo.

    ## Rules
    - No code comments; no markdown besides README.md and AGENTS.md.
    - No tests unless asked, except e2e tests of the built artifact under `nix flake check`.
    - Ship requested changes (commit, push, bump ~/finix pin, switch, restart affected services); ask before deleting untracked files, rewriting pushed history, or external actions.
  '';
  hostSection = lib.optionalString (host != []) ''

    ## Host
    ${lib.concatMapStringsSep "\n" (fact: "- ${fact}") host}
  '';
in {
  options.user.dev.prompts.agentsMd = {
    portable = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      description = "AGENTS.md content without host-specific finix facts.";
    };
    host = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      description = "Full ~/AGENTS.md content including host facts.";
    };
  };

  config = {
    user.dev.prompts.agentsMd = {
      inherit portable;
      host = portable + hostSection;
    };
    user.files."AGENTS.md".text = config.user.dev.prompts.agentsMd.host;
  };
}

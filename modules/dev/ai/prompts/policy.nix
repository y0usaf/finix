{
  config,
  lib,
  ...
}: let
  inherit (config.user.dev.prompts) host;

  rules = ''
    ## Rules
    - No code comments; no markdown besides README.md and AGENTS.md.
    - No tests unless asked, except e2e tests of the built artifact under `nix flake check`.
    - Ship requested changes (commit, push, bump ~/finix pin, switch, restart affected services); ask before deleting untracked files, rewriting pushed history, or external actions.
  '';

  hostFacts = ''
    ## Host
    ${lib.concatMapStringsSep "\n" (fact: "- ${fact}") host}'';
in {
  options.user.dev.prompts = {
    host = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Facts about this host that every agent session needs, each set by the module that owns it.";
    };
    shared = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      description = "What every coding-agent harness receives: rules and this host's facts, in markdown, with no trailing newline.";
    };
    portable = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      description = "The shared prompt without this host's facts, for agents that run somewhere else, such as the omp box.";
    };
  };

  config.user.dev.prompts = {
    host = lib.mkOrder 400 (
      ["Init: finit (`initctl`), sysklogd (`/var/log`); no systemd/`systemctl`/`journalctl`/`loginctl`."]
      ++ lib.optional ((config.fileSystems."/".fsType or null) == "tmpfs") "`/` is tmpfs (ephemeral across reboot outside persistent mounts)."
    );
    portable = lib.removeSuffix "\n" rules;
    shared = lib.concatMapStringsSep "\n\n" (lib.removeSuffix "\n") (
      [rules] ++ lib.optional (host != []) hostFacts
    );
  };
}

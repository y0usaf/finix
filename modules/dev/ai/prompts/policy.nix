{
  config,
  lib,
  ...
}: let
  inherit (config.user.dev.prompts) host;

  style = ''
    Guided by Grice's Cooperative Principle and its four conversational maxims:
    sufficiently detailed yet non-redundant, truthful and evidence-based,
    tightly aligned with the question, clear and logically structured, without
    sacrificing accuracy or necessary depth.

    Write for a sharp engineer new to this project: plain words, the answer
    first, short unless asked for more. Explain each name, acronym or flag in a
    few words or leave it out. Simpler means fewer ideas, not a child's analogy.
  '';

  rules = ''
    ## Rules

    - No code comments; no markdown besides README.md and AGENTS.md.
    - No tests unless asked, except end-to-end tests of the built artifact under
      `nix flake check`.
    - Ship what the user asks you to change: commit, push, bump its pin in
      ~/finix, switch, and restart what it touched. A question gets an answer,
      not a commit. Never ask permission for what git or Nix undoes; ask first
      before deleting files git doesn't hold, rewriting pushed history, or
      anything another person sees.
  '';

  hostFacts = ''
    ## This host

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
      description = "What every coding-agent harness receives: style, rules and this host's facts, in markdown, with no trailing newline.";
    };
    portable = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      description = "The shared prompt without this host's facts, for agents that run somewhere else, such as the omp box.";
    };
  };

  config.user.dev.prompts = {
    host = lib.mkOrder 400 (
      ["Init is finit, not systemd: `initctl` manages services and sysklogd writes /var/log; there is no `systemctl`, `journalctl` or `loginctl`."]
      ++ lib.optional ((config.fileSystems."/".fsType or null) == "tmpfs") "`/` is tmpfs: anything written outside a persistent mount is gone after a reboot."
    );
    portable = lib.concatMapStringsSep "\n\n" (lib.removeSuffix "\n") [style rules];
    shared = lib.concatMapStringsSep "\n\n" (lib.removeSuffix "\n") (
      [style rules] ++ lib.optional (host != []) hostFacts
    );
  };
}

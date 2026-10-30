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
  '';

  rules = ''
    ## Rules

    - Write no markdown files and no code comments; delete any your change makes
      wrong. Code states everything a comment would. A repo's README is its only
      prose; an existing plan, status or notes file is not precedent.
    - Write no tests, fixtures or snapshots unless asked, except end-to-end tests
      that drive the built artifact through its public interface without mocks
      under `nix flake check`, for behaviour a user would notice.
  '';

  shipping = ''
    ## Shipping

    Ship by default. Once a change passes its check, land it, push it, bump the
    system flake's pin of it, rebuild, switch, and restart what it touched once
    nothing runs there; then say what changed and the one command that undoes it.
    Git and Nix generations are the undo, so a reversible step never waits on the
    user and a question never asks permission for one. Ask first only before what
    neither undoes: deleting files git doesn't hold, rewriting pushed history,
    and anything another person sees, such as a message, a pull request or making
    a repo public. Before retrying a write whose outcome is unknown, check
    whether it took effect.
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
  };

  config.user.dev.prompts = {
    host = lib.mkOrder 400 (
      ["Init is finit, not systemd: `initctl` manages services and sysklogd writes /var/log; there is no `systemctl`, `journalctl` or `loginctl`."]
      ++ lib.optional ((config.fileSystems."/".fsType or null) == "tmpfs") "`/` is tmpfs: anything written outside a persistent mount is gone after a reboot."
    );
    shared = lib.concatMapStringsSep "\n\n" (lib.removeSuffix "\n") (
      [style rules shipping] ++ lib.optional (host != []) hostFacts
    );
  };
}

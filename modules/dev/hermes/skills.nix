# Declarative default-profile skill policy; never reconcile other profiles.
{ config, lib, pkgs, ... }:
let
  user = config.user.name;
  home = config.users.users.${user}.home;
  disabled = builtins.fromJSON (builtins.readFile ./skills/disabled.json);
  skillPaths = [
    "autonomous-ai-agents/hermes-agent"
    "autonomous-ai-agents/computer-use"
    "research/grounded-citations"
  ];
  files = lib.concatMap (skill: map (file: {
    name = ".hermes/skills/${skill}/${file}";
    value = {
      source = ./skills + "/${skill}/${file}";
      clobber = true; # Take over only these backed-up skill documents.
    };
  }) [ "SKILL.md" "references/detailed-guide.md" ]) skillPaths;
  applyPolicy = pkgs.writeShellScript "hermes-apply-skill-policy" ''
    set -eu
    export HOME=${lib.escapeShellArg home}
    export HERMES_HOME=${lib.escapeShellArg "${home}/.hermes"}
    exec ${config.user.dev.hermes.packages.hermesFull}/bin/hermes config set --force \
      skills.disabled ${lib.escapeShellArg (builtins.toJSON disabled)}
  '';
in {
  manzil.users.${user}.files = builtins.listToAttrs files;
  system.activation.scripts.hermesSkillPolicy = {
    deps = [ "users" ];
    text = ''
      ${pkgs.util-linux}/bin/runuser -u ${lib.escapeShellArg user} -- ${applyPolicy}
    '';
  };
}

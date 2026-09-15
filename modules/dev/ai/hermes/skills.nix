# Declarative default-profile skill policy; never reconcile other profiles.
{ config, lib, pkgs, flakeInputs, ... }:
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
      source = "${./skills/${skill}/${file}}";
      clobber = true; # Take over only these backed-up skill documents.
    };
  }) [ "SKILL.md" "references/detailed-guide.md" ]) skillPaths;
  # Hermes seeds bundled skills with `shutil.copytree`, preserving the store's
  # read-only 0555 directories — both the skill directory and, where the bundled
  # skill has one, its `references/` subdirectory. manzil places a file by
  # creating a sibling temp inside the target's own directory, so it needs u+w
  # there; without this the linker fails with "Permission denied (os error 13)"
  # and the whole manifest is left un-updated. Declare both directories
  # writable — attr values sort before their child paths, so each chmod runs
  # before the entries beneath it.
  #
  # force = false is REQUIRED: manzil rejects a `directory` entry carrying the
  # per-entry default force=true ("fatal: force is only valid for
  # symlink/copy/merge entries") and then places NOTHING from the manifest.
  dirs = map (path: {
    name = ".hermes/skills/${path}";
    value = {
      type = "directory";
      permissions = "0755";
      force = false;
    };
  }) (lib.concatMap (skill: [ skill "${skill}/references" ]) skillPaths);
  applyPolicy = pkgs.writeShellScript "hermes-apply-skill-policy" ''
    set -eu
    export HOME=${lib.escapeShellArg home}
    export HERMES_HOME=${lib.escapeShellArg "${home}/.hermes"}
    exec ${config.user.dev.ai.hermes.packages.hermesFull}/bin/hermes config set --force \
      skills.disabled ${lib.escapeShellArg (builtins.toJSON disabled)}
  '';
in {
  manzil.users.${user}.files = builtins.listToAttrs (files ++ dirs);
  system.activation.scripts.hermesSkillPolicy = {
    deps = [ "users" ];
    text = ''
      # Match Manzil's Finix uid/gid drop: Finix has no runuser PAM service.
      ${pkgs.util-linux}/bin/setpriv \
        --reuid "$(${pkgs.coreutils}/bin/id -u ${lib.escapeShellArg user})" \
        --regid "$(${pkgs.coreutils}/bin/id -g ${lib.escapeShellArg user})" \
        --clear-groups ${applyPolicy}
    '';
  };
}

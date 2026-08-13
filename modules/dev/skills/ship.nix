{
  config,
  lib,
  pkgs,
  ...
}: let
  # Shared skill: provisioned to every enabled agent's own skills dir (pi,
  # prime-agent, reasonix, ...). Kept out of modules/dev/pi/ so the skill is
  # not tied to one agent — extend the list to reach claude/codex too. Each
  # agent loads skills from <agentDir>/skills; the same content is placed in
  # each root. Reasonix's global skills root is ~/.reasonix/skills.
  roots =
    (lib.optional config.user.dev.pi.enable ".pi/agent/skills")
    ++ (lib.optional config.user.dev."prime-agent".enable ".prime/agent/skills")
    ++ (lib.optional config.user.dev.reasonix.enable ".reasonix/skills");

  mkFiles = root: {
    "${root}/ship/SKILL.md".source = ./ship/SKILL.md;
    "${root}/ship/scripts/system-flake" = {
      executable = true;
      text = ''
        #!${lib.getExe pkgs.python3}
        ${builtins.readFile ./ship/scripts/system-flake.py}
      '';
    };
  };
in {
  config = lib.mkIf (roots != []) {
    manzil.users."${config.user.name}".files = lib.mkMerge (map mkFiles roots);
  };
}

{
  config,
  lib,
  pkgs,
  ...
}: let
  skillRoot = ".local/share/pi/agent/skills/ship";
in {
  config = lib.mkIf config.user.dev.pi.enable {
    manzil.users."${config.user.name}".files = {
      "${skillRoot}/SKILL.md".source = ./ship/SKILL.md;
      "${skillRoot}/scripts/system-flake" = {
        executable = true;
        text = ''
          #!${lib.getExe pkgs.python3}
          ${builtins.readFile ./ship/scripts/system-flake.py}
        '';
      };
    };
  };
}

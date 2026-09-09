{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.lib.prompts) roots mkSkill;
in {
  config = lib.mkIf (roots != []) {
    manzil.users."${config.user.name}".files = lib.mkMerge (mkSkill "ship" {
      "SKILL.md".text = config.user.dev.prompts.skillText.ship;
      "scripts/system-flake" = {
        executable = true;
        text = ''
          #!${lib.getExe pkgs.python3}
          ${builtins.readFile ./ship/scripts/system-flake.py}
        '';
      };
    });
  };
}

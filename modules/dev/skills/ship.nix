{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (import ./mapping.nix {inherit config lib;}) roots mkSkill;
in {
  config = lib.mkIf (roots != []) {
    manzil.users."${config.user.name}".files = lib.mkMerge (mkSkill "ship" {
      "SKILL.md".text = import ./ship/SKILL.nix;
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

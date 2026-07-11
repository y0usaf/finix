{
  lib,
  pkgs,
  ...
}: {
  options = {
    user.gaming.mods.bg3 = lib.mkOption {
      type = with lib.types; attrsOf raw;
      default = {
        bg3se = {
          version = "updater-20240430";
        };

        "game-mods" = pkgs.fetchFromGitHub {
          owner = "y0usaf";
          repo = "game-mods";
          rev = "d54ec2dfad1e2116bf11c461e30d6fbf78e91df3";
          hash = "sha256-Vw7t9JGzi3mcz4lSgGtuq9GHKN8eZZX46LcmkCJGxdk=";
        };
      };
      internal = true;
    };
  };
}

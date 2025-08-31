{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.ui.ags.bar-overlay;
in {
  options.home.ui.ags.bar-overlay = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable AGS v2 Bar Overlay (Minimal time/date bars)";
    };
  };
  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name} = {
      packages = [
        pkgs.ags
      ];
      files = {
        ".config/ags/bar-overlay.tsx".source = ./config/bar-overlay.tsx;
        ".config/ags/tsconfig.json".source = ./config/tsconfig.json;
      };
    };
  };
}

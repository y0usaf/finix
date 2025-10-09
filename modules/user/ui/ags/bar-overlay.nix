{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.ui.ags.bar-overlay = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable AGS v2 Bar Overlay (Minimal time/date bars)";
    };
  };
  config = lib.mkIf config.user.ui.ags.bar-overlay.enable {
    environment.systemPackages = [
      pkgs.ags
    ];
    usr = {
      files = {
        ".config/ags/bar-overlay.tsx".source = ./config/bar-overlay.tsx;
        ".config/ags/tsconfig.json".source = ./config/tsconfig.json;
      };
    };
  };
}

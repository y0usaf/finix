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
  config = lib.mkIf config.user.ui.ags.bar-overlay.enable (
    let
      agsWithTray = pkgs.ags.override {
        extraPackages = with pkgs.astal; [
          tray
        ];
      };
    in {
      user.ui.ags.package = agsWithTray;
      environment.systemPackages = [
        agsWithTray
      ];
      usr = {
        files = {
          ".config/ags/bar-overlay.tsx".source = ./config/bar-overlay.tsx;
          ".config/ags/tsconfig.json".source = ./config/tsconfig.json;
        };
      };
    }
  );
}

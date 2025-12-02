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
      homeDir = "/home/${config.user.name}";
      barOverlay = pkgs.substitute {
        src = ./config/bar-overlay.tsx;
        substitutions = ["--subst-var-by" "HOME" homeDir];
      };
    in {
      user.ui.ags.package = agsWithTray;
      environment.systemPackages = [
        agsWithTray
      ];
      usr = {
        files = {
          ".config/ags/bar-overlay.tsx".source = barOverlay;
          ".config/ags/tsconfig.json".source = ./config/tsconfig.json;
        };
      };
    }
  );
}

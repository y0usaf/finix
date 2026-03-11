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
    modules = lib.mkOption {
      type = lib.types.listOf (lib.types.enum [
        "time"
        "date"
        "tray"
        "battery"
      ]);
      default = [
        "time"
        "date"
        "tray"
        "battery"
      ];
      description = "Bar overlay modules to enable";
    };
  };
  config = lib.mkIf config.user.ui.ags.bar-overlay.enable (
    let
      agsWithModules = pkgs.ags.override {
        extraPackages = with pkgs.astal; [
          tray
          battery
        ];
      };
    in {
      user.ui.ags.package = agsWithModules;
      environment.systemPackages = [
        agsWithModules
      ];
      usr = {
        files = {
          ".config/ags/bar-overlay.tsx".source = pkgs.substitute {
            src = ./config/bar-overlay.tsx;
            substitutions = [
              "--subst-var-by"
              "HOME"
              "/home/${config.user.name}"
              "--subst-var-by"
              "MODULES"
              (builtins.toJSON config.user.ui.ags.bar-overlay.modules)
            ];
          };
          ".config/ags/tsconfig.json".source = ./config/tsconfig.json;
        };
      };
    }
  );
}

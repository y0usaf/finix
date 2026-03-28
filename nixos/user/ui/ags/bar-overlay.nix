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
      inherit (pkgs) astal;
      agsWithModules = pkgs.ags.override {
        extraPackages = [
          astal.tray
          astal.battery
        ];
      };

      inherit (config) user;
    in {
      user.ui.ags.package = agsWithModules;
      environment.systemPackages = [
        agsWithModules
      ];
      bayt.users."${config.user.name}" = {
        files = {
          ".config/ags/bar-overlay.tsx".source = pkgs.substitute {
            src = ./config/bar-overlay.tsx;
            substitutions = [
              "--subst-var-by"
              "HOME"
              "/home/${user.name}"
              "--subst-var-by"
              "MODULES"
              (builtins.toJSON user.ui.ags.bar-overlay.modules)
            ];
          };
          ".config/ags/tsconfig.json".source = ./config/tsconfig.json;
        };
      };
    }
  );
}

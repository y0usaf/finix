{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf (config.user.ui.ags.enable or false) {
    user.ui.ags.bar-overlay.enable = lib.mkDefault true;
  };

  options.user.ui.ags = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable AGS v2 (defaults to bar-overlay)";
    };
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.ags;
      description = "AGS package to run (allows adding extra typelibs such as AstalTray).";
    };
  };
}

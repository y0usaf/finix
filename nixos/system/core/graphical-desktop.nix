{
  config,
  lib,
  pkgs,
  ...
}: {
  options.core.graphicalDesktop = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable essential graphical desktop packages and services";
    };

    headless = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Disable graphical desktop components for headless operation";
    };
  };

  config = lib.mkIf (config.core.graphicalDesktop.enable && !config.core.graphicalDesktop.headless) {
    environment.systemPackages = [
      pkgs.nixos-icons
      pkgs.xdg-utils
      pkgs.vicinae
    ];

    fonts.enableDefaultPackages = lib.mkDefault true;

    services.speechd.enable = lib.mkDefault true;

    hardware.graphics.enable = lib.mkDefault true;

    xdg = {
      autostart.enable = true;
      menus.enable = true;
      mime.enable = true;
      icons.enable = true;
    };

    services.xserver.desktopManager.runXdgAutostartIfNone = lib.mkDefault true;
  };
}

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
    # Core desktop packages (from services.graphical-desktop)
    environment.systemPackages = [
      pkgs.nixos-icons
      pkgs.xdg-utils
    ];

    fonts.enableDefaultPackages = lib.mkDefault true;

    services.speechd.enable = lib.mkDefault true;

    hardware.graphics.enable = lib.mkDefault true;

    # XDG desktop integration
    xdg = {
      autostart.enable = true;
      menus.enable = true;
      mime.enable = true;
      icons.enable = true;
    };

    # Essential for window managers - auto-starts applications when no DE present
    services.xserver.desktopManager.runXdgAutostartIfNone = lib.mkDefault true;
  };
}

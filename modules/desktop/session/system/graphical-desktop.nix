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
  };

  config = lib.mkIf config.core.graphicalDesktop.enable {
    environment.systemPackages = [
      pkgs.nixos-icons
      pkgs.playerctl
      pkgs.pulsemixer
      pkgs.xdg-utils
    ];
  };
}

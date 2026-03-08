{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.packages = {
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional packages to install";
    };
  };
  config = {
    environment.systemPackages =
      [
        pkgs.git
        pkgs.curl
        pkgs.wget
        pkgs.cachix
        pkgs.unzip
        pkgs.bash
        pkgs.lsd
        pkgs.tree
        pkgs.psmisc
        pkgs.dconf
        pkgs.lm_sensors
        pkgs.networkmanager
        pkgs.fzf
        pkgs.ripgrep
        pkgs.udiskie
        pkgs.playerctl
        pkgs.pulsemixer
      ]
      ++ config.user.packages.extraPackages;
  };
}

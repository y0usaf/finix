{
  config,
  lib,
  pkgs,
  ...
}: let
  basePackages = [
    pkgs.git
    pkgs.curl
    pkgs.wget
    pkgs.cachix
    pkgs.unzip
    pkgs.bash
    pkgs.lsd
    pkgs.alejandra
    pkgs.tree
    pkgs.btop
    pkgs.psmisc
    pkgs.dconf
    pkgs.lm_sensors
    pkgs.networkmanager
    pkgs.fzf
    pkgs.ripgrep
  ];
in {
  options.user.packages = {
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional packages to install";
    };
  };
  config = {
    environment.systemPackages = basePackages ++ config.user.packages.extraPackages;
  };
}

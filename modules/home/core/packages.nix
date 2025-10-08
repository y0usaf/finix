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
  options.home.core.packages = {
    enable = lib.mkEnableOption "core packages and base system tools";
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional packages to install";
    };
  };
  config = lib.mkIf config.home.core.packages.enable {
    environment.systemPackages = basePackages ++ config.home.core.packages.extraPackages;
  };
}

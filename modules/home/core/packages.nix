{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.core.packages;
  basePackages = with pkgs; [
    git
    curl
    wget
    cachix
    unzip
    bash
    lsd
    alejandra
    tree
    btop
    psmisc
    kitty
    dconf
    lm_sensors
    networkmanager
    fzf
    ripgrep
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
  config = lib.mkIf cfg.enable {
    environment.systemPackages = basePackages ++ cfg.extraPackages;
  };
}

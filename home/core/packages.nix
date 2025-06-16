###############################################################################
# Core Packages Module (Maid Version)
# Provides essential packages and default application configurations
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.cfg.home.core.packages;

  # Base packages all users should have
  basePackages = with pkgs; [
    # Essential CLI tools
    git
    curl
    wget
    cachix
    unzip
    bash
    vim
    lsd
    alejandra
    tree
    bottom
    psmisc
    kitty
    # System interaction
    dconf
    lm_sensors
    networkmanager
  ];
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.home.core.packages = {
    enable = lib.mkEnableOption "core packages and base system tools";
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional packages to install";
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Maid Configuration
    ###########################################################################
    users.users.y0usaf.maid.packages = basePackages ++ cfg.extraPackages;
  };
}

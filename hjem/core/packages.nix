###############################################################################
# Core Packages Module for Hjem
# Provides essential packages and default application configurations
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.cfg.hjome.core.packages;

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

    # System interaction
    dconf
    lm_sensors
    networkmanager
  ];
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.hjome.core.packages = {
    enable = lib.mkEnableOption "core packages and base system tools";
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional packages to install";
    };
  };

  # Define the option for collecting packages from modules
  options.packageCollector = {
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Packages to collect from all modules";
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkMerge [
    # Always add the collected packages to the top-level packages attribute
    {
      packages = config.packageCollector.packages;
    }
    # Add base packages when enabled
    (lib.mkIf cfg.enable {
      packageCollector.packages = basePackages ++ cfg.extraPackages;
    })
  ];
}

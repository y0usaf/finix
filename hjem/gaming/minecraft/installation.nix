###############################################################################
# Minecraft Installation Module - Hjem Version
# Provides PrismLauncher and client-side Minecraft support
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.cfg.hjome.gaming.minecraft;
in {
  options.cfg.hjome.gaming.minecraft = {
    prismlauncher = {
      enable = lib.mkEnableOption "PrismLauncher" // {default = cfg.enable;};
      
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.prismlauncher;
        description = "PrismLauncher package to use";
      };
      
      extraPackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = with pkgs; [
          # Common Java versions for different Minecraft versions
          temurin-bin-8
          temurin-bin-11 
          temurin-bin-17
          temurin-bin-21
        ];
        description = "Additional packages to install alongside PrismLauncher";
      };
    };

    servers = {
      skyfactory5 = {
        enable = lib.mkEnableOption "SkyFactory 5 Minecraft Server";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Note: In Hjem, packages are handled differently than traditional NixOS modules
    # System packages would need to be managed at the system level
    # For now, we just define the options structure
    
    # The actual PrismLauncher installation would need to be handled
    # by the system-level configuration or through a different mechanism
    # since Hjem focuses on user files and configurations
  };
}
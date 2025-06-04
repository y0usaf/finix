###############################################################################
# Hyprland Window Manager Module (Hjem Version)
# Configures the Hyprland Wayland compositor with:
# - Core settings and plugins (hy3)
# - Customizable keybindings and window rules
# - NVIDIA compatibility options
# - Configuration file generation using toHyprconf
###############################################################################
{
  config,
  pkgs,
  lib,
  inputs,
  hostSystem,
  hostHome,
  xdg,
  ...
}: let
  cfg = config.cfg.hjome.ui.hyprland;
  generators = import ../../../lib/generators/toHyprconf.nix lib;
  
  # Import all module configurations directly
  coreConfig = import ./core.nix { inherit config lib hostSystem cfg; };
  keybindingsConfig = import ./keybindings.nix { inherit config lib hostHome cfg; };
  windowRulesConfig = import ./window-rules.nix { inherit config lib cfg; };
  monitorsConfig = import ./monitors.nix { inherit config lib cfg; };
  agsConfig = import ./ags-integration.nix { inherit config lib hostHome cfg; };
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.hjome.ui.hyprland = {
    enable = lib.mkEnableOption "Hyprland window manager";
    flake = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to use Hyprland from flake inputs instead of nixpkgs";
      };
    };
    hy3 = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to enable the hy3 tiling layout plugin";
      };
    };
    group = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to enable the group layout mode";
      };
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    packages = [
      pkgs.hyprwayland-scanner # Tool associated with Hyprland
      (
        if cfg.flake.enable
        then inputs.hyprland.packages.${pkgs.system}.hyprland
        else pkgs.hyprland
      )
    ];

    ###########################################################################
    # Hyprland Configuration Files
    ###########################################################################
    files = {
      # Main Hyprland configuration
      ${xdg.configFile "hypr/hyprland.conf"}.text = let
        # Collect all configuration from modules
        hyprlandConfig = lib.foldl lib.recursiveUpdate {} [
          coreConfig
          keybindingsConfig
          windowRulesConfig
          monitorsConfig
          agsConfig
        ];

        # Generate plugins configuration if hy3 is enabled
        pluginsConfig = lib.optionalString cfg.hy3.enable (
          generators.pluginsToHyprconf [
            inputs.hy3.packages.${pkgs.system}.hy3
          ] ["$"]
        );

        # Generate main configuration
        mainConfig = generators.toHyprconf {
          attrs = hyprlandConfig;
          importantPrefixes = ["$" "exec" "source"];
        };
      in
        mainConfig + lib.optionalString (pluginsConfig != "") "\n${pluginsConfig}";

      # Hyprpaper configuration (if needed)
      ${xdg.configFile "hypr/hyprpaper.conf"}.text = ''
        preload = ${hostHome.cfg.directories.wallpapers.static.path}
        wallpaper = ,${hostHome.cfg.directories.wallpapers.static.path}
        splash = false
        ipc = on
      '';
    };
  };
}
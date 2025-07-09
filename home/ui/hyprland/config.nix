###############################################################################
# Hyprland Configuration Implementation (Maid Version)
# Main configuration logic for packages, files, and Hyprland setup
###############################################################################
{
  config,
  pkgs,
  lib,
  inputs,
  hostSystem,
  ...
}: let
  cfg = config.home.ui.hyprland;
  inherit (config.home.core) defaults;
  generators = import ../../../lib/generators/toHyprconf.nix lib;

  # Import all module configurations directly
  coreConfig = import ./core.nix {inherit config lib hostSystem cfg;};
  keybindingsConfig = import ./keybindings.nix {inherit lib defaults cfg;};
  windowRulesConfig = import ./window-rules.nix {inherit config lib cfg;};
  monitorsConfig = import ./monitors.nix {inherit config lib cfg;};
  agsConfig = import ./ags-integration.nix {inherit config lib cfg;};
  quickshellConfig = import ./quickshell-integration.nix {inherit config lib cfg;};
in {
  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    users.users.y0usaf.maid = {
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
        # Screenshot tools
        pkgs.grim
        pkgs.slurp
        pkgs.wl-clipboard
        # Wallpaper cycling dependencies
        pkgs.jq
        pkgs.swaybg
      ];

      ###########################################################################
      # Hyprland Configuration Files
      ###########################################################################
      file.xdg_config = {
        # Main Hyprland configuration
        "hypr/hyprland.conf" = {
          text = let
            # Merge all configuration from modules with proper list concatenation
            hyprlandConfig = let
              # Merge non-list attributes normally
              baseConfig = lib.foldl lib.recursiveUpdate {} [
                coreConfig
                windowRulesConfig
                monitorsConfig
              ];
              # Manually combine bind lists
              allBinds = (keybindingsConfig.bind or []) ++ (agsConfig.bind or []) ++ (quickshellConfig.bind or []);
              allBindm = (keybindingsConfig.bindm or []) ++ (agsConfig.bindm or []) ++ (quickshellConfig.bindm or []);
              allBindr = (keybindingsConfig.bindr or []) ++ (agsConfig.bindr or []) ++ (quickshellConfig.bindr or []);
              allBinds_hold = (keybindingsConfig.binds or []) ++ (agsConfig.binds or []) ++ (quickshellConfig.binds or []);
            in
              baseConfig
              // keybindingsConfig
              // agsConfig
              // quickshellConfig
              // {
                bind = allBinds;
                bindm = allBindm;
                bindr = allBindr;
                binds = allBinds_hold;
              };

            # Generate plugins configuration if hy3 is enabled
            pluginsConfig = lib.optionalString cfg.hy3.enable (
              generators.pluginsToHyprconf [
                (
                  if cfg.flake.enable
                  then inputs.hy3.packages.${pkgs.system}.hy3
                  else pkgs.hyprlandPlugins.hy3
                )
              ] ["$"]
            );

            # Generate main configuration
            mainConfig = generators.toHyprconf {
              attrs = hyprlandConfig;
              importantPrefixes = ["$" "exec" "source"];
            };
          in
            mainConfig + lib.optionalString (pluginsConfig != "") "\n${pluginsConfig}";
        };

        # Hyprpaper configuration (if needed)
        "hypr/hyprpaper.conf" = {
          text = ''
            preload = ${config.home.directories.wallpapers.static.path}
            wallpaper = ,${config.home.directories.wallpapers.static.path}
            splash = false
            ipc = on
          '';
        };
      };
    };
  };
}

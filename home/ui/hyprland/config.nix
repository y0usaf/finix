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
        # Wallpaper cycling dependency
        pkgs.jq
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
              # Temporarily include essential keybindings directly
              essentialBinds = [
                # Essential Controls
                "$mod, Q, killactive"
                "$mod, M, exit"
                "$mod, F, fullscreen"
                "$mod, TAB, layoutmsg, orientationnext"
                "$mod, space, togglefloating"
                "$mod, P, pseudo"

                # Primary Applications
                "$mod, D, exec, ${defaults.terminal}"
                "$mod, E, exec, ${defaults.fileManager}"
                "$mod, R, exec, ${defaults.launcher}"
                "$mod, O, exec, ${defaults.terminal} -e ${defaults.editor}"
                "$mod2, 1, exec, ${defaults.ide}"
                "$mod2, 2, exec, ${defaults.browser}"
                "$mod2, 3, exec, ${defaults.discord}"
                "$mod2, 4, exec, steam"
                "$mod2, 5, exec, obs"

                # Window Movement (WASD keys)
                "$mod2, w, movefocus, u"
                "$mod2, a, movefocus, l"
                "$mod2, s, movefocus, d"
                "$mod2, d, movefocus, r"
                "$mod2 SHIFT, w, movewindow, u"
                "$mod2 SHIFT, a, movewindow, l"
                "$mod2 SHIFT, s, movewindow, d"
                "$mod2 SHIFT, d, movewindow, r"

                # Workspace Management (1-9)
                "$mod, 1, workspace, 1"
                "$mod, 2, workspace, 2"
                "$mod, 3, workspace, 3"
                "$mod, 4, workspace, 4"
                "$mod, 5, workspace, 5"
                "$mod, 6, workspace, 6"
                "$mod, 7, workspace, 7"
                "$mod, 8, workspace, 8"
                "$mod, 9, workspace, 9"
                "$mod SHIFT, 1, movetoworkspacesilent, 1"
                "$mod SHIFT, 2, movetoworkspacesilent, 2"
                "$mod SHIFT, 3, movetoworkspacesilent, 3"
                "$mod SHIFT, 4, movetoworkspacesilent, 4"
                "$mod SHIFT, 5, movetoworkspacesilent, 5"
                "$mod SHIFT, 6, movetoworkspacesilent, 6"
                "$mod SHIFT, 7, movetoworkspacesilent, 7"
                "$mod SHIFT, 8, movetoworkspacesilent, 8"
                "$mod SHIFT, 9, movetoworkspacesilent, 9"

                # System Controls
                "Ctrl$mod2,Delete, exec, gnome-system-monitor"
                "$mod Shift, M, exec, shutdown now"
                "Ctrl$mod2Shift, M, exec, reboot"

                # Utility Commands
                "$mod, G, exec, grim -g \"$(slurp -d)\" - | wl-copy -t image/png"
                "$mod SHIFT, G, exec, grim - | wl-copy -t image/png"
                "$mod, GRAVE, exec, hyprpicker | wl-copy"
              ];

              # Manually combine bind lists
              allBinds = essentialBinds ++ (agsConfig.bind or []) ++ (quickshellConfig.bind or []);
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

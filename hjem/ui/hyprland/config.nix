###############################################################################
# Hyprland Configuration Implementation
# Main configuration logic for packages, files, and Hyprland setup
###############################################################################
{
  config,
  pkgs,
  lib,
  inputs,
  hostSystem,
  hostHome,
  hostHjem,
  ...
}: let
  cfg = config.cfg.hjome.ui.hyprland;
  generators = import ../../../lib/generators/toHyprconf.nix lib;



  # Import all module configurations directly
  coreConfig = import ./core.nix {inherit config lib hostSystem cfg;};
  keybindingsConfig = import ./keybindings.nix {inherit lib hostHjem cfg;};
  windowRulesConfig = import ./window-rules.nix {inherit config lib cfg;};
  monitorsConfig = import ./monitors.nix {inherit config lib cfg;};
  agsConfig = import ./ags-integration.nix {inherit config lib cfg;};
in {
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
      ".config/hypr/hyprland.conf" = {
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
              "$mod, D, exec, $term"
              "$mod, E, exec, $filemanager"
              "$mod, R, exec, $launcher"
              "$mod, O, exec, $notepad"
              "$mod2, 1, exec, $ide"
              "$mod2, 2, exec, $browser"
              "$mod2, 3, exec, $discord"
              "$mod2, 4, exec, steam"
              "$mod2, 5, exec, $obs"
              
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
            allBinds = essentialBinds ++ (agsConfig.bind or []);
            allBindm = (keybindingsConfig.bindm or []) ++ (agsConfig.bindm or []);
            allBindr = (keybindingsConfig.bindr or []) ++ (agsConfig.bindr or []);
          in baseConfig // keybindingsConfig // agsConfig // {
            bind = allBinds;
            bindm = allBindm;
            bindr = allBindr;
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

          # Debug: Write the merged config to a debug file
          debugConfig = builtins.toJSON hyprlandConfig;
          
          # Generate main configuration
          mainConfig = generators.toHyprconf {
            attrs = hyprlandConfig;
            importantPrefixes = ["$" "exec" "source"];
          };
        in
          mainConfig + lib.optionalString (pluginsConfig != "") "\n${pluginsConfig}";
      };

      # Hyprpaper configuration (if needed)

      ".config/hypr/hyprpaper.conf" = {
        text = ''
          preload = ${hostHjem.cfg.hjome.directories.wallpapers.static.path}
          wallpaper = ,${hostHjem.cfg.hjome.directories.wallpapers.static.path}
          splash = false
          ipc = on
        '';
      };
    };
  };
}

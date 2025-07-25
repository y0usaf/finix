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
  generators = import ../../../../lib/generators/toHyprconf.nix lib;
  coreConfig = import ./core.nix {inherit config lib hostSystem cfg;};
  keybindingsConfig = import ./keybindings.nix {inherit lib config defaults cfg;};
  windowRulesConfig = import ./window-rules.nix {inherit config lib cfg;};
  monitorsConfig = import ./monitors.nix {inherit config lib cfg;};
  agsConfig = import ./ags-integration.nix {inherit config lib cfg;};
  quickshellConfig = import ./quickshell-integration.nix {inherit config lib cfg;};
in {
  config = lib.mkIf cfg.enable {
    users.users.${config.user.name}.maid = {
      packages = [
        pkgs.hyprwayland-scanner
        pkgs.hyprland # Use nixpkgs version for npins compatibility
        pkgs.grim
        pkgs.slurp
        pkgs.wl-clipboard
        pkgs.jq
        pkgs.swaybg
      ];
      file.xdg_config = {
        "hypr/hyprland.conf" = {
          text = let
            hyprlandConfig = let
              baseConfig = lib.foldl lib.recursiveUpdate {} [
                coreConfig
                windowRulesConfig
                monitorsConfig
              ];
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
            pluginsConfig = lib.optionalString cfg.hy3.enable (
              generators.pluginsToHyprconf [
                (
                  if cfg.flake.enable
                  then inputs.hy3.packages.${pkgs.system}.hy3
                  else pkgs.hyprlandPlugins.hy3
                )
              ] ["$"]
            );
            mainConfig = generators.toHyprconf {
              attrs = hyprlandConfig;
              importantPrefixes = ["$" "exec" "source"];
            };
          in
            mainConfig + lib.optionalString (pluginsConfig != "") "\n${pluginsConfig}";
        };
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

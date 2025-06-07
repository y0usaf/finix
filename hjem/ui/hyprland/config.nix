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
  xdg,
  ...
}: let
  cfg = config.cfg.hjome.ui.hyprland;
  generators = import ../../../lib/generators/toHyprconf.nix lib;

  # Hyprland Configuration Merge Helper
  hyprlandMerge = let
    # Attributes that should have their lists concatenated instead of replaced
    listAttributes = [
      "bind"
      "bindr"
      "bindm"
      "exec-once"
      "windowrule"
      "windowrulev2"
      "layerrule"
      "env"
      "bezier"
    ];

    # Check if an attribute should be treated as a concatenatable list
    isListAttribute = name: builtins.elem name listAttributes;

    # Merge two configuration objects with proper list handling
    mergeConfigs = left: right: let
      # Get all attribute names from both configs
      allNames = lib.unique (builtins.attrNames left ++ builtins.attrNames right);

      # Merge each attribute appropriately
      mergedAttrs = lib.genAttrs allNames (
        name: let
          leftVal = left.${name} or [];
          rightVal = right.${name} or [];
          leftExists = builtins.hasAttr name left;
          rightExists = builtins.hasAttr name right;
        in
          if isListAttribute name
          then
            # Concatenate lists for list attributes
            (
              if leftExists
              then leftVal
              else []
            )
            ++ (
              if rightExists
              then rightVal
              else []
            )
          else if leftExists && rightExists
          then
            # For non-list attributes, use recursiveUpdate if both are attrs, otherwise right wins
            if builtins.isAttrs leftVal && builtins.isAttrs rightVal
            then lib.recursiveUpdate leftVal rightVal
            else rightVal
          else if leftExists
          then leftVal
          else rightVal
      );
    in
      mergedAttrs;

    # Merge multiple configuration objects
    mergeMultipleConfigs = configs:
      lib.foldl mergeConfigs {} configs;
  in {
    inherit mergeConfigs mergeMultipleConfigs;
  };

  # Import all module configurations directly
  coreConfig = import ./core.nix {inherit config lib hostSystem cfg;};
  keybindingsConfig = import ./keybindings.nix {inherit config lib hostHome hostHjem cfg;};
  windowRulesConfig = import ./window-rules.nix {inherit config lib cfg;};
  monitorsConfig = import ./monitors.nix {inherit config lib cfg;};
  agsConfig = import ./ags-integration.nix {inherit config lib hostHome hostHjem cfg;};
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
      ${xdg.configFile "hypr/hyprland.conf"}.text = let
        # Collect all configuration from modules using proper merge function
        hyprlandConfig = hyprlandMerge.mergeMultipleConfigs [
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
        preload = ${hostHjem.cfg.hjome.directories.wallpapers.static.path}
        wallpaper = ,${hostHjem.cfg.hjome.directories.wallpapers.static.path}
        splash = false
        ipc = on
      '';
    };
  };
}

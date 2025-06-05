###############################################################################
# Obsidian Module
# Knowledge base application with Wayland support
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.hjome.programs.obsidian;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.hjome.programs.obsidian = {
    enable = lib.mkEnableOption "Obsidian module";
    useWayland = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable Wayland/Ozone support for Obsidian";
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    packages = with pkgs; [
      # Create a wrapper script for Obsidian with Wayland support
      (writeShellScriptBin "obsidian" ''
        # Set Wayland/Ozone environment variables if enabled
        ${lib.optionalString cfg.useWayland ''
          export NIXOS_OZONE_WL=1
          export ELECTRON_OZONE_PLATFORM_HINT=wayland
        ''}

        # Launch Obsidian with performance optimizations
        exec ${obsidian}/bin/obsidian \
          --disable-smooth-scrolling \
          --enable-gpu-rasterization \
          --enable-zero-copy \
          ${lib.optionalString cfg.useWayland "--ozone-platform-hint=wayland"} \
          "$@"
      '')
    ];
  };
}
#===============================================================================
#                      📝 Obsidian Configuration 📝
#===============================================================================
# 🚀 Obsidian Knowledge Base
# 🔧 Performance optimizations
# 🎨 Wayland/Ozone support
#===============================================================================
{
  config,
  pkgs,
  lib,
  hostSystem,
  hostHome,
  ...
}: let
  cfg = config.cfg.programs.obsidian;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.programs.obsidian = {
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
    home.packages = with pkgs; [
      # Create a wrapper script in PATH for Obsidian
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

    # Add Obsidian-specific environment variables
    programs.zsh = {
      envExtra = lib.mkIf cfg.useWayland ''
        # Obsidian environment variables for Wayland/Ozone
        export OBSIDIAN_USE_WAYLAND=1
      '';
    };

    # Create desktop entry with proper icon and categories
    xdg.desktopEntries = {
      "obsidian" = {
        name = "Obsidian";
        exec = "obsidian %U";
        terminal = false;
        categories = ["Office" "TextEditor" "Utility"];
        comment = "Knowledge base that works on top of a local folder of Markdown files";
        icon = "obsidian";
        mimeType = ["x-scheme-handler/obsidian"];
      };
    };
  };
}

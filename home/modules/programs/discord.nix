#===============================================================================
#                      💬 Discord Canary Configuration 💬
#===============================================================================
# 🚀 Discord Canary
# 🔧 Performance optimizations
# 🎨 Integration with system theme
#===============================================================================
{
  config,
  pkgs,
  lib,
  hostSystem,
  hostHome,
  ...
}: let
  cfg = config.cfg.programs.discord;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.programs.discord = {
    enable = lib.mkEnableOption "Discord module";
    variant = lib.mkOption {
      type = lib.types.enum ["canary" "stable"];
      default = "canary";
      description = "Which Discord variant to install (canary or stable)";
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      (if cfg.variant == "canary" then
        # Create a wrapper script in PATH for Discord Canary
        (writeShellScriptBin "discord-canary" ''
          exec ${(discord-canary.override {
            withOpenASAR = true;
            # No Vencord
          })}/opt/DiscordCanary/DiscordCanary \
            --disable-smooth-scrolling \
            --disable-features=WebRtcAllowInputVolumeAdjustment \
            --enable-gpu-rasterization \
            --enable-zero-copy \
            "$@"
        '')
      else
        # Create a wrapper script in PATH for Discord Stable
        (writeShellScriptBin "discord" ''
          exec ${discord}/bin/discord \
            --disable-smooth-scrolling \
            --disable-features=WebRtcAllowInputVolumeAdjustment \
            --enable-gpu-rasterization \
            --enable-zero-copy \
            "$@"
        '')
      )
    ];

    # Add Discord-specific environment variables
    programs.zsh = {
      envExtra = lib.mkIf hostSystem.cfg.hardware.nvidia.enable ''
        # Discord environment variables for NVIDIA
        export DISCORD_SKIP_HOST_VIDEO_CODEC_BLACKLIST=1
      '';
    };

    # Create desktop entry with proper icon and categories
    xdg.desktopEntries = {
      "discord-canary" = {
        name = "Discord Canary";
        exec = "discord-canary %U";
        terminal = false;
        categories = ["Network" "InstantMessaging" "Chat"];
        comment = "Discord Canary";
        icon = "discord-canary";
        mimeType = ["x-scheme-handler/discord"];
      };
    };
  };
}

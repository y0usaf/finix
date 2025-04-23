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
    enable = lib.mkEnableOption "Discord Canary module";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
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
    ];

    # Add Discord-specific environment variables
    programs.zsh = {
      envExtra = lib.mkIf hostSystem.cfg.core.nvidia.enable ''
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

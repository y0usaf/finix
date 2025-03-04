#===============================================================================
#                      💬 Discord Configuration 💬
#===============================================================================
# 🚀 Discord with Vencord client mods
# 🔧 Performance optimizations
# 🎨 Integration with system theme
#===============================================================================
{
  config,
  pkgs,
  lib,
  profile,
  ...
}: {
  config = lib.mkIf (builtins.elem "discord" profile.features) {
    home.packages = with pkgs; [
      # Create a wrapper script in PATH that includes Discord with Vencord
      (writeShellScriptBin "discord" ''
        exec ${(discord.override {
          withOpenASAR = true;
          withVencord = true;
        })}/opt/Discord/Discord \
          --disable-smooth-scrolling \
          --disable-features=WebRtcAllowInputVolumeAdjustment \
          --enable-gpu-rasterization \
          --enable-zero-copy \
          "$@"
      '')
    ];

    # Add Discord-specific environment variables
    programs.zsh = {
      envExtra = lib.mkIf (builtins.elem "nvidia" profile.features) ''
        # Discord environment variables for NVIDIA
        export DISCORD_SKIP_HOST_VIDEO_CODEC_BLACKLIST=1
      '';
    };

    # Create desktop entry with proper icon and categories
    xdg.desktopEntries = {
      discord = {
        name = "Discord";
        exec = "discord %U";
        terminal = false;
        categories = ["Network" "InstantMessaging" "Chat"];
        comment = "Discord with Vencord";
        icon = "discord";
        mimeType = ["x-scheme-handler/discord"];
      };
    };
  };
}

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
      (pkgs.symlinkJoin {
        name = "discord-canary-with-flags";
        paths = [
          (discord-canary.override {
            withOpenASAR = true;
            withVencord = true;
          })
        ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          mkdir -p $out/bin
          if [ ! -e $out/bin/discord-canary ]; then
            ln -s $out/opt/DiscordCanary/DiscordCanary $out/bin/discord-canary
          fi
          wrapProgram $out/bin/discord-canary \
            --add-flags "--disable-smooth-scrolling" \
            --add-flags "--disable-features=WebRtcAllowInputVolumeAdjustment" \
            --add-flags "--enable-gpu-rasterization" \
            --add-flags "--enable-zero-copy"
        '';
      })
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
      discord-canary = {
        name = "Discord Canary";
        exec = "discord-canary %U";
        terminal = false;
        categories = ["Network" "InstantMessaging" "Chat"];
        comment = "Discord Canary with Vencord";
        icon = "discord-canary";
        mimeType = ["x-scheme-handler/discord"];
      };
    };
  };
}

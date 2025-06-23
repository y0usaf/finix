#===============================================================================
#                      💬 Discord Configuration (Maid) 💬
#===============================================================================
# 🚀 Discord Canary
# 🔧 Performance optimizations
# 🎨 Integration with system theme
#===============================================================================
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.programs.discord;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.programs.discord = {
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
    ###########################################################################
    # Maid Configuration
    ###########################################################################
    users.users.y0usaf.maid.packages = with pkgs; [
      (
        if cfg.variant == "canary"
        then
          # Create a wrapper script in PATH for Discord Canary
          (writeShellScriptBin "discord-canary" ''
            exec ${(discord-canary.override {
              withOpenASAR = true;
              withVencord = true;
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
            exec ${(discord.override {
              withOpenASAR = true;
              withVencord = true;
            })}/bin/discord \
              --disable-smooth-scrolling \
              --disable-features=WebRtcAllowInputVolumeAdjustment \
              --enable-gpu-rasterization \
              --enable-zero-copy \
              "$@"
          '')
      )
    ];
  };
}

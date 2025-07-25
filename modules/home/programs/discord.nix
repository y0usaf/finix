{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.programs.discord;
in {
  options.home.programs.discord = {
    enable = lib.mkEnableOption "Discord module";
    variant = lib.mkOption {
      type = lib.types.enum ["canary" "stable"];
      default = "canary";
      description = "Which Discord variant to install (canary or stable)";
    };
  };
  config = lib.mkIf cfg.enable {
    users.users.${config.user.name}.maid.packages = with pkgs; [
      (
        if cfg.variant == "canary"
        then
          (writeShellScriptBin "discord-canary" ''
            exec ${(discord-canary.override {
              withOpenASAR = true;
              withVencord = true;
            })}/opt/DiscordCanary/DiscordCanary \
              --enable-features=UseOzonePlatform,WaylandWindowDecorations \
              --ozone-platform=wayland \
              --disable-smooth-scrolling \
              --disable-features=WebRtcAllowInputVolumeAdjustment \
              --disable-gpu-sandbox \
              --enable-gpu-rasterization \
              "$@"
          '')
        else
          (writeShellScriptBin "discord" ''
            exec ${(discord.override {
              withOpenASAR = true;
              withVencord = true;
            })}/bin/discord \
              --enable-features=UseOzonePlatform \
              --ozone-platform=wayland \
              --disable-smooth-scrolling \
              --enable-gpu-rasterization \
              --enable-zero-copy \
              --disable-features=WebRtcAllowInputVolumeAdjustment \
              "$@"
          '')
      )
    ];
  };
}

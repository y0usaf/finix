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
            export DISPLAY=:0
            exec ${(discord-canary.override {
              withOpenASAR = true;
              withVencord = true;
            })}/opt/DiscordCanary/DiscordCanary \
              --disable-smooth-scrolling \
              --disable-features=WebRtcAllowInputVolumeAdjustment \
              "$@"
          '')
        else
          (writeShellScriptBin "discord" ''
            export DISPLAY=:0
            exec ${(discord.override {
              withOpenASAR = true;
              withVencord = true;
            })}/bin/discord \
              --disable-smooth-scrolling \
              --disable-features=WebRtcAllowInputVolumeAdjustment \
              "$@"
          '')
      )
    ];
  };
}

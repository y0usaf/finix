{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) concatStringsSep optionals mkEnableOption mkOption mkIf types;

  disableFeatures = [
    "WebRtcAllowInputVolumeAdjustment"
    "ChromeWideEchoCancellation"
  ];
  inherit (config) user;
  userName = user.name;
  stableCfg = user.programs.discord.stable;
in {
  options.user.programs.discord.stable = {
    enable = mkEnableOption "Discord stable";
    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Extra command line arguments to pass to Discord";
    };
    minimizeToTray =
      mkEnableOption "Minimize to tray on close"
      // {default = false;};
    smoothScroll =
      mkEnableOption "Smooth scrolling"
      // {default = true;};
  };

  config = mkIf stableCfg.enable {
    environment.systemPackages = [
      (pkgs.discord.override {
        commandLineArgs = concatStringsSep " " ((optionals (disableFeatures != []) [
            "--disable-features=${concatStringsSep "," disableFeatures}"
          ]
          ++ optionals (!stableCfg.smoothScroll) [
            "--disable-smooth-scrolling"
          ])
        ++ stableCfg.extraArgs);
        withOpenASAR = true;
        disableUpdates = false;
        withTTS = false;
        enableAutoscroll = true;
      })
    ];

    hjem.users."${userName}".files = {
      ".config/discord/settings.json" = {
        generator = lib.generators.toJSON {};
        value = {
          SKIP_HOST_UPDATE = true;
          UPDATE_ENDPOINT = "https://inject.shelter.uwu.network/vencord";
          NEW_UPDATE_ENDPOINT = "https://inject.shelter.uwu.network/vencord/";
          MINIMIZE_TO_TRAY = stableCfg.minimizeToTray;
          OPEN_ON_STARTUP = false;
          DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING = true;
          enableHardwareAcceleration = false;
          openasar = {
            setup = true;
            cmdPreset = "balanced";
            quickstart = false;
            css = ''
              @import url("file:///home/${userName}/.config/Vencord/themes/disblock.css");
              @import url("file:///home/${userName}/.config/Vencord/themes/visual-refresh-hide-2.css");
              @import url("file:///home/${userName}/.config/Vencord/themes/visual-refresh-hide-3.css");
              @import url("file:///home/${userName}/.config/Vencord/themes/visual-refresh-hide-4.css");
              @import url("file:///home/${userName}/.config/Vencord/themes/visual-refresh-hide-5.css");
              @import url("file:///home/${userName}/.config/Vencord/themes/system-font.css");
            '';
          };
        };
      };
    };
  };
}

{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) concatStringsSep optionals mkEnableOption mkOption mkIf types;

  enableFeatures = [
    "WaylandLinuxDrmSyncobj"
  ];
  disableFeatures = [
    "WebRtcAllowInputVolumeAdjustment"
    "ChromeWideEchoCancellation"
  ];
  inherit (config) user;
  userName = user.name;
  canaryCfg = user.programs.discord.canary;
in {
  options.user.programs.discord.canary = {
    enable = mkEnableOption "Discord Canary";
    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Extra command line arguments to pass to Discord Canary";
    };
    minimizeToTray =
      mkEnableOption "Minimize to tray on close"
      // {default = false;};
    smoothScroll =
      mkEnableOption "Smooth scrolling"
      // {default = true;};
  };

  config = mkIf canaryCfg.enable {
    environment.systemPackages = [
      (pkgs.discord-canary.override {
        commandLineArgs = concatStringsSep " " ((optionals (enableFeatures != []) [
            "--enable-features=${concatStringsSep "," enableFeatures}"
          ]
          ++ optionals (disableFeatures != []) [
            "--disable-features=${concatStringsSep "," disableFeatures}"
          ]
          ++ optionals (!canaryCfg.smoothScroll) [
            "--disable-smooth-scrolling"
          ])
        ++ canaryCfg.extraArgs);
        withOpenASAR = true;
        disableUpdates = false;
        withTTS = false;
        enableAutoscroll = true;
      })
    ];

    bayt.users."${userName}".files.".config/discordcanary/settings.json" = {
      generator = lib.generators.toJSON {};
      value = {
        SKIP_HOST_UPDATE = true;
        UPDATE_ENDPOINT = "https://inject.shelter.uwu.network/vencord";
        NEW_UPDATE_ENDPOINT = "https://inject.shelter.uwu.network/vencord/";
        MINIMIZE_TO_TRAY = canaryCfg.minimizeToTray;
        OPEN_ON_STARTUP = false;
        DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING = true;
        enableHardwareAcceleration = true;
        openH264Enabled = true;
        openasar = {
          setup = true;
          cmdPreset = "balanced";
          quickstart = false;
          css =
            # css
            ''
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
}

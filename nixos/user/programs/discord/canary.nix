{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) concatStringsSep optionals mkEnableOption mkOption mkIf;

  disableFeatures = [
    "WebRtcAllowInputVolumeAdjustment"
    "ChromeWideEchoCancellation"
  ];

  gpuArgs =
    optionals (disableFeatures != []) [
      "--disable-features=${concatStringsSep "," disableFeatures}"
    ]
    ++ optionals (!config.user.programs.discord.canary.smoothScroll) [
      "--disable-smooth-scrolling"
    ];

  commandLineArgs = concatStringsSep " " (gpuArgs ++ config.user.programs.discord.canary.extraArgs);
in {
  options.user.programs.discord.canary = {
    enable = mkEnableOption "Discord Canary";
    extraArgs = mkOption {
      type = lib.types.listOf lib.types.str;
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

  config = mkIf config.user.programs.discord.canary.enable {
    environment.systemPackages = [
      (pkgs.discord-canary.override {
        inherit commandLineArgs;
        withOpenASAR = true;
        disableUpdates = false;
        withTTS = false;
        enableAutoscroll = true;
      })
    ];

    hjem.users.${config.user.name}.files.".config/discordcanary/settings.json" = {
      generator = lib.generators.toJSON {};
      value = {
        SKIP_HOST_UPDATE = true;
        UPDATE_ENDPOINT = "https://inject.shelter.uwu.network/vencord";
        NEW_UPDATE_ENDPOINT = "https://inject.shelter.uwu.network/vencord/";
        MINIMIZE_TO_TRAY = config.user.programs.discord.canary.minimizeToTray;
        OPEN_ON_STARTUP = false;
        DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING = true;
        enableHardwareAcceleration = false;
        openasar = {
          setup = true;
          cmdPreset = "balanced";
          quickstart = false;
          css =
            # css
            ''
              @import url("file:///home/${config.user.name}/.config/Vencord/themes/disblock.css");
              @import url("file:///home/${config.user.name}/.config/Vencord/themes/visual-refresh-hide-2.css");
              @import url("file:///home/${config.user.name}/.config/Vencord/themes/visual-refresh-hide-3.css");
              @import url("file:///home/${config.user.name}/.config/Vencord/themes/visual-refresh-hide-4.css");
              @import url("file:///home/${config.user.name}/.config/Vencord/themes/visual-refresh-hide-5.css");
              @import url("file:///home/${config.user.name}/.config/Vencord/themes/system-font.css");
            '';
        };
      };
    };
  };
}

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
in {
  options.user.programs.discord.stable = {
    enable = mkEnableOption "Discord stable";
    extraArgs = mkOption {
      type = lib.types.listOf lib.types.str;
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

  config = mkIf config.user.programs.discord.stable.enable {
    environment.systemPackages = [
      (pkgs.discord.override {
        commandLineArgs = concatStringsSep " " ((optionals (disableFeatures != []) [
            "--disable-features=${concatStringsSep "," disableFeatures}"
          ]
          ++ optionals (!config.user.programs.discord.stable.smoothScroll) [
            "--disable-smooth-scrolling"
          ])
        ++ config.user.programs.discord.stable.extraArgs);
        withOpenASAR = true;
        disableUpdates = false;
        withTTS = false;
        enableAutoscroll = true;
      })
    ];

    hjem.users."${config.user.name}".files = {
      ".config/discord/settings.json" = {
        generator = lib.generators.toJSON {};
        value = {
          SKIP_HOST_UPDATE = true;
          UPDATE_ENDPOINT = "https://inject.shelter.uwu.network/vencord";
          NEW_UPDATE_ENDPOINT = "https://inject.shelter.uwu.network/vencord/";
          MINIMIZE_TO_TRAY = config.user.programs.discord.stable.minimizeToTray;
          OPEN_ON_STARTUP = false;
          DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING = true;
          enableHardwareAcceleration = false;
          openasar = {
            setup = true;
            cmdPreset = "balanced";
            quickstart = false;
            css = ''
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
  };
}

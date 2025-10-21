{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  options.user.programs.vesktop = {
    enable = mkEnableOption "Vesktop (Discord client) module";
  };

  config = mkIf config.user.programs.vesktop.enable {
    environment.systemPackages = [pkgs.vesktop];
    usr = {
      files = {
        ".config/vesktop/settings.json" = {
          source = (pkgs.formats.json {}).generate "vesktop-settings.json" {
            discordBranch = "stable";
            minimizeToTray = false;
            arRPC = false;
            splashColor = "rgb(219, 220, 223)";
          };
        };

        ".config/vesktop/settings/settings.json" = {
          source = settingsFormat.generate "vencord-settings.json" {
            autoUpdate = true;
            autoUpdateNotification = true;
            useQuickCss = true;
            enabledThemes = [];
            themeLinks = [];
            frameless = false;
            transparent = false;

            eagerPatches = false;
            enableReactDevtools = false;
            winCtrlQ = false;
            disableMinSize = false;
            winNativeTitleBar = false;

            plugins = {
              CommandsAPI.enabled = true;
              MessageAccessoriesAPI.enabled = true;
              MessageEventsAPI.enabled = true;
              UserSettingsAPI.enabled = true;
              CrashHandler.enabled = true;
              FakeNitro = {
                enabled = true;
                enableStickerBypass = true;
                enableStreamQualityBypass = true;
                enableEmojiBypass = true;
                transformEmojis = true;
                transformStickers = true;
                transformCompoundSentence = false;
              };
              ShikiCodeblocks.enabled = true;
              WebKeybinds.enabled = true;
              WebScreenShareFixes.enabled = true;
              BadgeAPI.enabled = true;
              NoTrack = {
                enabled = true;
                disableAnalytics = true;
              };
              Settings = {
                enabled = true;
                settingsLocation = "aboveNitro";
              };
              DisableDeepLinks.enabled = true;
              SupportHelper.enabled = true;
              WebContextMenus.enabled = true;
            };

            notifications = {
              timeout = 5000;
              position = "bottom-right";
              useNative = "not-focused";
              logLimit = 50;
            };

            cloud = {
              authenticated = false;
              url = "https://api.vencord.dev/";
              settingsSync = false;
              settingsSyncVersion = 1756398454870;
            };
          };
        };

        ".config/vesktop/state.json" = {
          source = (pkgs.formats.json {}).generate "vesktop-state.json" {
            firstLaunch = false;
            windowBounds = {
              x = 0;
              y = 0;
              width = 2543;
              height = 1418;
            };
            displayId = 43;
          };
        };
      };
    };
  };
}

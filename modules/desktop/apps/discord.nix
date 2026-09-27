{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (lib) concatStringsSep;

  enableFeatures = [
    "WaylandWindowDecorations"
    "WaylandLinuxDrmSyncobj"
  ];
  disableFeatures = [
    "WebRtcAllowInputVolumeAdjustment"
    "ChromeWideEchoCancellation"
  ];
  inherit (config) user;
  userName = user.name;
  legacyDir = "${flakeInputs.nixpkgs-discord-legacy}/pkgs/applications/networking/instant-messengers/discord";
  legacySource = (lib.importJSON "${legacyDir}/sources.json")."linux-stable";
  legacyDiscord = pkgs.callPackage "${legacyDir}/linux.nix" {
    pname = "discord";
    inherit (legacySource) version;
    src = pkgs.fetchurl {inherit (legacySource) url hash;};
    branch = "stable";
    binaryName = "Discord";
    desktopName = "Discord";
    self = legacyDiscord;
    meta = {
      description = "All-in-one cross-platform voice and text chat for gamers";
      mainProgram = "Discord";
    };
  };
  wrapFonts = names: lib.concatStringsSep ", " (map (f: "\"${f}\"") names);
  inherit (config.user.ui) fonts;
  uiFontList = [fonts.mainFontName fonts.backup.name];
  primaryFont = wrapFonts (uiFontList ++ [fonts.emoji.name]);
in {
  finix.persistence.allowlist.users.${userName}.directories = [
    ".config/discord"
    ".config/discordcanary"
    ".config/Vencord"
    ".config/vesktop"
  ];
  environment.systemPackages = [
    pkgs.vesktop
    (legacyDiscord.override {
      commandLineArgs = "--enable-features=${concatStringsSep "," enableFeatures} --disable-features=${concatStringsSep "," disableFeatures}";
      withOpenASAR = true;
      disableUpdates = false;
      withTTS = false;
      enableAutoscroll = true;
    })
  ];

  manzil.users."${userName}".files = {
    ".config/discord/settings.json" = {
      generator = lib.generators.toJSON {};
      value = {
        SKIP_HOST_UPDATE = true;
        SKIP_MODULE_UPDATE = true;
        MINIMIZE_TO_TRAY = false;
        OPEN_ON_STARTUP = false;
        DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING = true;
        enableHardwareAcceleration = true;
        openH264Enabled = true;
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
            @import url("file:///home/${userName}/.config/Vencord/themes/wallust-colors.css");
          '';
        };
      };
    };

    ".config/Vencord/themes/disblock.css".text = ''
      :root {
        --display-clan-tags: none;
        --display-active-now: none;
        --display-hover-reaction-emoji: none;
        --bool-show-name-gradients: false;
      }
    '';

    ".config/Vencord/themes/system-font.css".text = ''
      :root {
        /* Use system fonts for UI */
        --font-primary: ${primaryFont} !important;
        --font-display: ${primaryFont} !important;
        --font-headline: ${primaryFont} !important;
        --font-code: ${wrapFonts uiFontList} !important;
      }
    '';

    ".config/Vencord/themes/visual-refresh.css".text = ''
      /* Hide the Visual Refresh title bar */
      .visual-refresh {
        --custom-app-top-bar-height: 0px !important;
        div.base__5e434 > div.bar_c38106 {
          display: none;
        }
      }

      /* Adjust guild list top offset after hiding title bar */
      .visual-refresh {
        ul[data-list-id="guildsnav"] > div.itemsContainer_ef3116 {
          margin-top: 8px;
        }
      }

      /* Make "Read All" vencord button text smaller */
      button.vc-ranb-button {
        font-size: 9.5pt;
        font-weight: normal;
      }

      /* Hide Discover button */
      div[data-list-item-id="guildsnav___guild-discover-button"] {
        display: none !important;
      }

      /* Hide the buttons next to mute and deafen */
      div[class^=buttons__] {
        gap: 2px;
        div[class^=micButtonParent__] {
          button[role="switch"] {
            border-radius: var(--radius-sm) !important;
            ~ button {
              display: none;
            }
          }
        }
      }
    '';

    ".config/vesktop/settings.json" = {
      generator = lib.generators.toJSON {};
      value = {
        discordBranch = "stable";
        minimizeToTray = false;
        arRPC = false;
        splashColor = "rgb(219, 220, 223)";
      };
    };

    ".config/vesktop/settings/settings.json" = {
      generator = lib.generators.toJSON {};
      value = {
        autoUpdate = true;
        autoUpdateNotification = true;
        useQuickCss = true;
        enabledThemes = ["wallust-colors.css"];
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
      generator = lib.generators.toJSON {};
      value = {
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
}

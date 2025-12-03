{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) concatStringsSep optionals mkEnableOption mkOption mkIf;
  cfg = config.user.programs.discord.canary;

  disableFeatures = [
    "WebRtcAllowInputVolumeAdjustment"
    "ChromeWideEchoCancellation"
  ];

  enableFeatures = [];

  gpuArgs =
    optionals (enableFeatures != []) [
      "--enable-features=${concatStringsSep "," enableFeatures}"
    ]
    ++ optionals (disableFeatures != []) [
      "--disable-features=${concatStringsSep "," disableFeatures}"
    ]
    ++ optionals (!cfg.smoothScroll) [
      "--disable-smooth-scrolling"
    ];

  commandLineArgs = concatStringsSep " " (gpuArgs ++ cfg.extraArgs);

  font = config.user.ui.fonts;
  wrapFonts = fonts: concatStringsSep ", " (map (f: "\"${f}\"") fonts);
  primaryFont = wrapFonts [font.mainFontName font.backup.name font.emoji.name];
  monoFont = wrapFonts [font.mainFontName font.backup.name];
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

  config = mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.discord-canary.override {
        inherit commandLineArgs;
        withOpenASAR = false;
        withVencord = true;
        withTTS = false;
        enableAutoscroll = true;
      })
    ];

    hjem.users.${config.user.name}.files.".config/discordcanary/settings.json" = {
      generator = lib.generators.toJSON {};
      value = {
        SKIP_HOST_UPDATE = true;
        MINIMIZE_TO_TRAY = cfg.minimizeToTray;
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
              /* Hide nitro begging */
              @import url("https://raw.codeberg.page/AllPurposeMat/Disblock-Origin/DisblockOrigin.theme.css");

              /* Hide the Visual Refresh title bar */
              .visual-refresh {
                --custom-app-top-bar-height: 0 !important;
                div.base__5e434 > div.bar_c38106 {
                  display: none;
                }
                ul[data-list-id="guildsnav"] > div.itemsContainer_ef3116 {
                  margin-top: 8px;
                }
              }

              :root {
                /* Use system fonts for UI */
                --font-primary: ${primaryFont} !important;
                --font-display: ${primaryFont} !important;
                --font-headline: ${primaryFont} !important;
                --font-code: ${monoFont} !important;

                /* Disblock settings */
                --display-clan-tags: none;
                --display-active-now: none;
                --display-hover-reaction-emoji: none;
                --bool-show-name-gradients: false;
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
        };
      };
    };
  };
}

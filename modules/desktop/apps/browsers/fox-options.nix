{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkOption types;
  attrsOfAnything = types.attrsOf types.anything;
  hwAccel = config.user.programs.browser.hardwareAccel;
  uiFonts = config.user.ui.fonts;
  fontList = lib.concatStringsSep ", " [
    uiFonts.mainFontName
    uiFonts.backup.name
    "Symbols Nerd Font"
    uiFonts.emoji.name
  ];
in {
  options.user.programs = {
    firefox.enable = mkEnableOption "Firefox browser";
    librewolf.enable = mkEnableOption "LibreWolf browser";

    browser = {
      hardwareAccel = {
        webrender = mkOption {
          type = types.bool;
          default = true;
          description = "Enable WebRender in Firefox-family browsers.";
        };

        videoDecoding = mkOption {
          type = types.bool;
          default = true;
          description = "Enable hardware video decoding in Firefox-family browsers.";
        };

        vaapi = mkOption {
          type = types.bool;
          default = false;
          description = "Enable VA-API acceleration in Firefox-family browsers.";
        };

        disabled = mkOption {
          type = types.bool;
          default = false;
          description = "Disable browser layer acceleration.";
        };
      };

      shared = {
        policies = mkOption {
          type = attrsOfAnything;
          internal = true;
          default = {};
          description = "Shared Firefox-family browser policies.";
        };

        lockedPrefs = mkOption {
          type = attrsOfAnything;
          internal = true;
          default = {};
          description = "Shared locked Firefox-family browser preferences.";
        };

        defaultPrefs = mkOption {
          type = attrsOfAnything;
          internal = true;
          default = {};
          description = "Shared default Firefox-family browser preferences.";
        };

        userChromeCss = mkOption {
          type = types.lines;
          internal = true;
          default = "";
          description = "Shared Firefox-family userChrome.css content.";
        };

        userContentCss = mkOption {
          type = types.lines;
          internal = true;
          default = "";
          description = "Shared Firefox-family userContent.css content.";
        };
      };
    };
  };

  config.user.programs.browser.shared = {
    policies = {
      DisableTelemetry = true;
      DisablePocket = true;
      DisableFormHistory = true;
      NoDefaultBookmarks = true;
      NewTabPage = false;
      FirefoxHome = {
        Search = false;
        TopSites = false;
        Highlights = false;
        Pocket = false;
        Snippets = false;
        Locked = true;
      };
      Homepage = {
        URL = "about:blank";
        Locked = true;
        StartPage = "homepage";
      };
      EnableTrackingProtection = {
        Value = true;
        Locked = false;
      };
      SearchEngines = {
        PreventInstalls = true;
        Add = [
          {
            Name = "Google";
            URLTemplate = "https://www.google.com/search?q={searchTerms}";
          }
        ];
        Remove = [
          "DuckDuckGo"
          "Wikipedia (en)"
          "Bing"
        ];
        Default = "Google";
      };
      SanitizeOnShutdown = {
        History = true;
        FormData = true;
        Downloads = true;
        Sessions = true;
        Cookies = false;
        Cache = true;
        SiteSettings = false;
        OfflineApps = true;
      };
      ExtensionSettings = {
        "*" = {
          installation_mode = "blocked";
          allowed_types = ["extension" "theme"];
        };
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
          allowed_in_private_browsing = true;
        };
        "jid1-QoFqdK4qzUfGWQ@jetpack" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/dark-background-light-text/latest.xpi";
          installation_mode = "force_installed";
          allowed_in_private_browsing = true;
        };
        "vimium-c@gdh1995.cn" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-c/latest.xpi";
          installation_mode = "force_installed";
          allowed_in_private_browsing = true;
        };
        "{aecec67f-0d10-4fa7-b7c7-609a2db280cf}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/violentmonkey/latest.xpi";
          installation_mode = "force_installed";
          allowed_in_private_browsing = true;
        };
        "twitch5@coolcmd" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/twitch_5/latest.xpi";
          installation_mode = "force_installed";
          allowed_in_private_browsing = true;
        };
        "sponsorBlocker@ajay.app" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi";
          installation_mode = "force_installed";
          allowed_in_private_browsing = true;
        };
        "pywalfox@frewacom.org" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/pywalfox/latest.xpi";
          installation_mode = "force_installed";
          allowed_in_private_browsing = true;
        };
        "conventional-comments-addon@pullpo.io" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/conventional-comments-pullpo/latest.xpi";
          installation_mode = "force_installed";
          allowed_in_private_browsing = true;
        };
      };
    };

    lockedPrefs = {
      "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

      "browser.theme.content-theme" = 0;
      "browser.theme.toolbar-theme" = 0;
      "browser.uidensity" = 1;

      "extensions.webextensions.remote" = true;

      "browser.tabs.inTitlebar" = 0;
      "browser.toolbars.bookmarks.visibility" = "never";

      "gfx.webrender.all" = hwAccel.webrender;
      "media.hardware-video-decoding.enabled" = hwAccel.videoDecoding;
      "media.ffmpeg.vaapi.enabled" = hwAccel.vaapi;
      "layers.acceleration.disabled" = hwAccel.disabled;

      "browser.sessionstore.interval" = 15000;
      "network.http.max-persistent-connections-per-server" = 10;
      "browser.cache.disk.enable" = false;
      "browser.cache.memory.enable" = true;
      "browser.cache.memory.capacity" = 1048576;
      "browser.sessionhistory.max_entries" = 50;
      "network.prefetch-next" = true;

      "browser.theme.dark-private-windows" = false;

      "dom.webcomponents.enabled" = true;
      "layout.css.shadow-parts.enabled" = true;

      "browser.ml.enable" = false;
      "browser.ml.chat.enabled" = false;
      "extensions.ml.enabled" = false;
      "browser.ml.linkPreview.enabled" = false;
      "browser.tabs.groups.smart.enabled" = false;
      "browser.tabs.groups.smart.userEnabled" = false;

      "privacy.resistFingerprinting" = false;

      "font.name-list.monospace.x-unicode" = fontList;
      "font.name-list.monospace.x-western" = fontList;
      "font.name-list.sans-serif.x-unicode" = fontList;
      "font.name-list.sans-serif.x-western" = fontList;
      "font.name-list.serif.x-unicode" = fontList;
      "font.name-list.serif.x-western" = fontList;

      # Audio processing disables for better microphone quality
      "media.getusermedia.audio.processing.aec" = 0;
      "media.getusermedia.audio.processing.aec.enabled" = false;
      "media.getusermedia.audio.processing.agc" = 0;
      "media.getusermedia.audio.processing.agc.enabled" = false;
      "media.getusermedia.audio.processing.agc2.forced" = false;
      "media.getusermedia.audio.processing.noise" = 0;
      "media.getusermedia.audio.processing.noise.enabled" = false;
      "media.getusermedia.audio.processing.hpf.enabled" = false;
    };

    defaultPrefs = {
      "browser.display.use_document_fonts" = 0;
    };
  };
}

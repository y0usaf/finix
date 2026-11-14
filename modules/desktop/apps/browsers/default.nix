{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  userName = config.user.name;
  librewolfPkgs = import flakeInputs.nixpkgs-librewolf {inherit (pkgs.stdenv.hostPlatform) system;};
  nixUserscripts = false;
  uiFonts = config.user.ui.fonts;
  fontList = lib.concatStringsSep ", " [
    uiFonts.mainFontName
    uiFonts.backup.name
    "Symbols Nerd Font"
    uiFonts.emoji.name
  ];
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
      "jid1-QoFqdK4qzUfGWQ@jetpack".installation_mode = "blocked";
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
      "conventional-comments-addon@pullpo.io" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/conventional-comments-pullpo/latest.xpi";
        installation_mode = "force_installed";
        allowed_in_private_browsing = true;
      };
    };
  };

  lockedPrefs = {
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

    "browser.theme.content-theme" = 2;
    "browser.theme.toolbar-theme" = 2;
    "layout.css.prefers-color-scheme.content-override" = 2;
    "browser.uidensity" = 1;
    "browser.nova.enabled" = true;

    "extensions.webextensions.remote" = true;

    "browser.tabs.inTitlebar" = 0;
    "browser.toolbars.bookmarks.visibility" = "never";

    "media.hardware-video-decoding.enabled" = true;
    "media.ffmpeg.vaapi.enabled" = true;
    "widget.dmabuf.force-enabled" = true;

    "browser.sessionstore.interval" = 15000;
    "network.http.max-persistent-connections-per-server" = 10;
    "browser.cache.disk.enable" = true;
    "browser.sessionhistory.max_entries" = 50;
    "network.prefetch-next" = true;

    "browser.theme.dark-private-windows" = false;

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

    "media.getusermedia.audio.processing.aec" = 0;
    "media.getusermedia.audio.processing.aec.enabled" = false;
    "media.getusermedia.audio.processing.agc" = 0;
    "media.getusermedia.audio.processing.agc.enabled" = false;
    "media.getusermedia.audio.processing.agc2.forced" = false;
    "media.getusermedia.audio.processing.noise" = 0;
    "media.getusermedia.audio.processing.noise.enabled" = false;
    "media.getusermedia.audio.processing.hpf.enabled" = false;
  };
in {
  user.persist.directories = [
    ".cache/librewolf"
    ".config/firefox"
    ".config/librewolf"
    ".librewolf"
    ".mozilla"
  ];
  environment.systemPackages = [
    ((librewolfPkgs.librewolf-bin.override {
      extraPrefs =
        lib.concatMapAttrsStringSep "\n" (name: value: "lockPref(\"${name}\", ${builtins.toJSON value});") lockedPrefs
        + "\ndefaultPref(\"browser.display.use_document_fonts\", 0);";
      extraPolicies =
        policies
        // {DisableFirefoxAccounts = false;}
        // lib.optionalAttrs nixUserscripts {
          "3rdparty".Extensions."nix-userscripts@y0usaf".scripts = map (file: {code = builtins.readFile file;}) [
            ./userscripts/4chan-x.user.js
            ./userscripts/twitchadsolutions-video-swap-new.user.js
            ./userscripts/twitchadsolutions-vaft.user.js
            ./userscripts/browse-instagram-without-logging-in.user.js
            ./userscripts/instagram-redirect.user.js
            ./userscripts/frankerfacez.user.js
            ./userscripts/taobao-search-plus.user.js
            ./userscripts/undiscord.user.js
            ./userscripts/youtube-auto-buffer-auto-hd.user.js
            ./userscripts/youtube-hd-plus.user.js
            ./userscripts/glassdoor-paywall-remover.user.js
            ./userscripts/netflix-uhd.user.js
            ./userscripts/see-more-without-logging-into-facebook.user.js
            ./userscripts/clean-up-linkedin-posts.user.js
            ./userscripts/youtube-anti-shorts.user.js
            ./userscripts/return-pagination-to-google.user.js
            ./userscripts/facebook-login-bypass.user.js
            ./userscripts/reddit-overwrite-not-spammy.user.js
            ./userscripts/bypass-login-on-mature-posts.user.js
            ./userscripts/remove-sponsored-kijiji-listings.user.js
            ./userscripts/x-translator.user.js
          ];
        };
    }).overrideAttrs (old: {
      makeWrapperArgs = old.makeWrapperArgs ++ ["--set" "NVD_BACKEND" "direct" "--set" "MOZ_DISABLE_RDD_SANDBOX" "1"];
    }))
  ];
  user.files = {
    ".librewolf/profiles.ini" = {
      generator = lib.generators.toINI {};
      value = {
        Profile0 = {
          Name = "default";
          IsRelative = 1;
          Path = userName;
          Default = 1;
        };
        General = {
          StartWithLastProfile = 1;
          Version = 2;
        };
      };
    };
    ".librewolf/${userName}/chrome/userChrome.css".text = builtins.readFile ./userChrome.css;
  };
}

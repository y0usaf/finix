{
  config,
  lib,
  pkgs,
  flakeInputs,
  generators,
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
    ".librewolf/${userName}/chrome/userChrome.css".text = generators.cssSource [
      {
        select = ":root";
        set = [
          ["--font-family" "monospace"]
          ["--chrome-font-size" "11px"]
          ["--bar-pad" "3px"]
          ["--bar-width" "75vw"]
          ["--bar-height" "calc(var(--chrome-font-size) + 2 * var(--bar-pad))"]
          ["--breakout-width" "50vw"]
          ["--breakout-top" "20vh"]
          ["--chrome-text" "var(--toolbar-text-color, -moz-dialogtext)"]
          ["--chrome-dim" "color-mix(in srgb, currentColor 55%, transparent)"]
          ["--chrome-line" "var(--toolbar-field-border-color, light-dark(#d6d5da, #3f3e42))"]
          ["--chrome-selected" "var(--tab-background-color-selected, light-dark(#e9e9ed, #3e3d42))"]
          ["--chrome-field" "var(--toolbar-field-background-color, light-dark(#ffffff, #1c1b22))"]
          ["--chrome-glass" "color-mix(in srgb, var(--chrome-field) 84%, transparent)"]
          ["--chrome-accent" "AccentColor"]
          ["--tab-min-height" "var(--bar-height) !important"]
          ["--tab-block-margin" "0px !important"]
          ["--tab-margin-block" "0px !important"]
          ["--tab-inline-padding" "0.5em !important"]
          ["--tab-label-line-height" "1 !important"]
          ["--tab-close-button-padding" "0px !important"]
          ["--tab-icon-end-margin" "0.4em !important"]
          ["--urlbar-min-height" "var(--bar-height) !important"]
          ["--urlbar-height" "var(--bar-height) !important"]
          ["--urlbar-container-height" "var(--bar-height) !important"]
          ["--toolbarbutton-inner-padding" "var(--bar-pad) !important"]
          ["--toolbarbutton-outer-padding" "0px !important"]
          ["--toolbarbutton-padding-inner" "var(--bar-pad) !important"]
          ["--toolbarbutton-padding-outer" "0px !important"]
          ["--toolbar-start-end-padding" "0px !important"]
          ["--urlbarview-row-pad" "0.25em"]
          ["--urlbarview-row-min" "1.6em"]
          ["--urlbarView-row-gutter" "0px !important"]
          ["--panel-border-radius" "0px !important"]
          ["--arrowpanel-border-radius" "0px !important"]
          ["--toolbarbutton-border-radius" "0px !important"]
          ["--tab-border-radius" "0px !important"]
          ["--urlbar-border-radius" "0px !important"]
          ["--urlbar-inner-border-radius" "0px !important"]
          ["--urlbarView-row-border-radius" "0px !important"]
          ["--urlbarView-icon-border-radius" "0px !important"]
          ["--urlbar-background-inset" "0px !important"]
          ["--panel-menuitem-border-radius" "0px !important"]
          ["--button-border-radius" "0px !important"]
          ["--border-radius-small" "0px !important"]
          ["--border-radius-medium" "0px !important"]
          ["--border-radius-large" "0px !important"]
          ["--border-radius-xlarge" "0px !important"]
          ["--border-radius-xxlarge" "0px !important"]
        ];
      }
      {
        select = ":root, panel, menupopup";
        set = [
          ["font-family" "var(--font-family) !important"]
          ["font-size" "var(--chrome-font-size) !important"]
          ["color" "var(--chrome-text) !important"]
        ];
      }
      {
        select = "#navigator-toolbox";
        set = [
          ["display" "contents !important"]
          ["border" "0 !important"]
          ["background" "transparent !important"]
        ];
      }
      {
        select = "#toolbar-menubar[inactive]";
        set = [
          ["display" "none !important"]
        ];
      }
      {
        select = "#toolbar-menubar:not([inactive])";
        set = [
          ["order" "-1 !important"]
          ["height" "var(--bar-height) !important"]
          ["min-height" "0 !important"]
          ["padding" "0 !important"]
          ["background" "transparent !important"]
        ];
      }
      {
        select = "#browser";
        set = [
          ["padding" "0 !important"]
        ];
      }
      {
        select = "#PersonalToolbar, #statuspanel, .titlebar-buttonbox-container, .titlebar-spacer";
        set = [
          ["display" "none !important"]
        ];
      }
      {
        select = "#TabsToolbar, #nav-bar";
        set = [
          ["width" "var(--bar-width) !important"]
          ["margin-inline" "auto !important"]
          ["margin-block" "0 !important"]
          ["padding" "0 !important"]
          ["border" "0 !important"]
          ["background" "transparent !important"]
          ["font-size" "var(--chrome-font-size) !important"]
        ];
      }
      {
        select = "#TabsToolbar";
        set = [
          ["height" "var(--bar-height) !important"]
          ["min-height" "0 !important"]
          ["max-height" "var(--bar-height) !important"]
          ["align-items" "center !important"]
        ];
      }
      {
        select = "#nav-bar";
        set = [
          ["order" "1 !important"]
          ["position" "relative !important"]
          ["height" "var(--bar-height) !important"]
          ["min-height" "0 !important"]
          ["max-height" "var(--bar-height) !important"]
          ["align-items" "center !important"]
        ];
      }
      {
        select = "toolbarspring, #customizableui-special-spring1, #customizableui-special-spring2";
        set = [
          ["display" "none !important"]
        ];
      }
      {
        select = "#back-button, #forward-button, #stop-reload-button";
        set = [
          ["order" "-2 !important"]
        ];
      }
      {
        select = "#nav-bar-customization-target > #downloads-button";
        set = [
          ["order" "0 !important"]
          ["margin-inline-start" "auto !important"]
        ];
      }
      {
        select = "#fxa-toolbar-menu-button";
        set = [
          ["order" "1 !important"]
        ];
      }
      {
        select = "#nav-bar-customization-target";
        set = [
          ["min-width" "0 !important"]
          ["align-items" "center !important"]
        ];
      }
      {
        select = "#TabsToolbar-customization-target";
        set = [
          ["min-width" "0 !important"]
          ["height" "var(--bar-height) !important"]
          ["align-items" "center !important"]
        ];
      }
      {
        select = "#tabbrowser-tabs, #tabbrowser-arrowscrollbox, #pinned-tabs-container";
        set = [
          ["min-height" "0 !important"]
          ["height" "var(--bar-height) !important"]
          ["align-items" "center !important"]
        ];
      }
      {
        select = "#tabbrowser-arrowscrollbox:not([overflowing])";
        set = [
          ["justify-content" "center !important"]
        ];
      }
      {
        select = ".tabbrowser-tab";
        set = [
          ["height" "var(--bar-height) !important"]
          ["min-height" "0 !important"]
          ["padding" "0 !important"]
          ["margin" "0 !important"]
          ["align-items" "center !important"]
        ];
      }
      {
        select = ".tabbrowser-tab .tab-stack, .tabbrowser-tab .tab-content";
        set = [
          ["height" "100% !important"]
          ["margin" "0 !important"]
          ["align-items" "center !important"]
        ];
      }
      {
        select = ".tabbrowser-tab .tab-content";
        set = [
          ["padding-inline" "var(--tab-inline-padding) !important"]
        ];
      }
      {
        select = ".tabbrowser-tab .tab-label-container";
        set = [
          ["min-width" "0 !important"]
          ["overflow" "hidden !important"]
        ];
      }
      {
        select = ".tabbrowser-tab .tab-background";
        set = [
          ["margin" "0 !important"]
          ["border" "0 !important"]
          ["border-radius" "0 !important"]
          ["background" "transparent !important"]
        ];
      }
      {
        select = ".tabbrowser-tab[selected] .tab-background, .tabbrowser-tab[visuallyselected] .tab-background";
        set = [
          ["background-color" "var(--chrome-selected) !important"]
        ];
      }
      {
        select = ".tabbrowser-tab:hover:not([selected]) .tab-background";
        set = [
          ["background-color" "color-mix(in srgb, currentColor 8%, transparent) !important"]
        ];
      }
      {
        select = ".tabbrowser-tab .tab-label";
        set = [
          ["line-height" "1 !important"]
          ["margin" "0 !important"]
        ];
      }
      {
        select = ".tab-icon-image, .tab-throbber, .tab-icon-pending, .tab-icon-overlay, .tab-audio-button";
        set = [
          ["width" "1em !important"]
          ["height" "1em !important"]
          ["min-width" "0 !important"]
          ["padding" "0 !important"]
          ["margin-inline-end" "var(--tab-icon-end-margin) !important"]
        ];
      }
      {
        select = ".tabbrowser-tab .tab-close-button";
        set = [
          ["width" "1em !important"]
          ["height" "1em !important"]
          ["padding" "0 !important"]
          ["margin-inline-start" "0.4em !important"]
          ["border-radius" "0 !important"]
          ["background" "transparent !important"]
          ["opacity" "0.6"]
        ];
      }
      {
        select = ".tabbrowser-tab .tab-close-button:hover";
        set = [
          ["opacity" "1"]
          ["background-color" "color-mix(in srgb, currentColor 18%, transparent) !important"]
        ];
      }
      {
        select = "#TabsToolbar toolbarbutton, #nav-bar toolbarbutton, #nav-bar .toolbarbutton-1";
        set = [
          ["appearance" "none !important"]
          ["min-width" "0 !important"]
          ["min-height" "0 !important"]
          ["height" "calc(var(--bar-height) - 2px) !important"]
          ["margin" "0 !important"]
          ["padding" "0 var(--bar-pad) !important"]
          ["border" "0 !important"]
          ["border-radius" "0 !important"]
          ["background" "transparent !important"]
        ];
      }
      {
        select = "#tabs-newtab-button, #vertical-tabs-newtab-button";
        set = [
          ["display" "none !important"]
        ];
      }
      {
        select = "#new-tab-button, #alltabs-button";
        set = [
          ["display" "flex !important"]
          ["flex" "0 0 auto !important"]
          ["margin-inline-start" "0 !important"]
        ];
      }
      {
        select = "#TabsToolbar .toolbarbutton-icon, #nav-bar .toolbarbutton-icon, #nav-bar .toolbarbutton-badge-stack, #nav-bar .unified-extensions-item .toolbarbutton-badge-stack";
        set = [
          ["width" "1em !important"]
          ["height" "1em !important"]
          ["min-width" "0 !important"]
          ["padding" "0 !important"]
          ["margin" "0 !important"]
        ];
      }
      {
        select = "#nav-bar .unified-extensions-item, #nav-bar #PanelUI-button";
        set = [
          ["height" "var(--bar-height) !important"]
          ["min-height" "0 !important"]
          ["align-items" "center !important"]
          ["margin" "0 !important"]
        ];
      }
      {
        select = "#urlbar-container";
        set = [
          ["position" "absolute !important"]
          ["inset-inline" "0 !important"]
          ["top" "0 !important"]
          ["bottom" "0 !important"]
          ["height" "var(--bar-height) !important"]
          ["width" "var(--breakout-width) !important"]
          ["max-width" "100% !important"]
          ["min-width" "0 !important"]
          ["margin-inline" "auto !important"]
          ["margin-block" "0 !important"]
          ["padding" "0 !important"]
          ["z-index" "5 !important"]
        ];
      }
      {
        select = "#urlbar";
        set = [
          ["height" "var(--bar-height) !important"]
          ["min-height" "0 !important"]
          ["margin" "0 !important"]
          ["padding" "0 !important"]
          ["border" "0 !important"]
          ["border-radius" "0 !important"]
          ["background" "transparent !important"]
          ["box-shadow" "none !important"]
          ["font-size" "var(--chrome-font-size) !important"]
          ["text-align" "center !important"]
        ];
      }
      {
        select = "#urlbar > .urlbar-background";
        set = [
          ["background" "transparent !important"]
          ["border" "0 !important"]
          ["border-radius" "0 !important"]
          ["box-shadow" "none !important"]
        ];
      }
      {
        select = "#urlbar:not([breakout-extend]) > .urlbar-input-container";
        set = [
          ["height" "var(--bar-height) !important"]
          ["min-height" "0 !important"]
          ["padding" "0 !important"]
          ["border" "0 !important"]
        ];
      }
      {
        select = "#urlbar-input";
        set = [
          ["position" "absolute !important"]
          ["inset-inline" "0 !important"]
          ["top" "0 !important"]
          ["height" "100% !important"]
          ["width" "auto !important"]
          ["font-size" "var(--chrome-font-size) !important"]
          ["text-align" "center !important"]
          ["margin" "0 !important"]
          ["padding-inline" "4.5em !important"]
          ["outline" "none !important"]
        ];
      }
      {
        select = "#urlbar > .urlbar-input-container";
        set = [
          ["position" "relative !important"]
          ["padding" "0 !important"]
        ];
      }
      {
        select = ".urlbar-input-box";
        set = [
          ["position" "absolute !important"]
          ["inset-inline" "0 !important"]
          ["top" "0 !important"]
          ["height" "100% !important"]
          ["margin" "0 !important"]
        ];
      }
      {
        select = "#identity-box, #tracking-protection-icon-container, .urlbar-page-action, #urlbar-searchmode-switcher, #urlbar-go-button, #urlbar-revert-button-container";
        set = [
          ["position" "relative !important"]
          ["z-index" "2 !important"]
        ];
      }
      {
        select = "#urlbar-input::placeholder";
        set = [
          ["opacity" "0.5 !important"]
        ];
      }
      {
        select = "#urlbar[focused]:not([breakout-extend]) > .urlbar-background";
        set = [
          ["background-color" "var(--chrome-field) !important"]
          ["outline" "1px solid var(--chrome-line) !important"]
          ["outline-offset" "-1px !important"]
        ];
      }
      {
        select = "#identity-box, #identity-box:hover, #tracking-protection-icon-container";
        set = [
          ["border-radius" "0 !important"]
          ["background" "transparent !important"]
        ];
      }
      {
        select = ".urlbar-icon, #identity-box image, #identity-icon, #identity-permission-box image";
        set = [
          ["width" "1em !important"]
          ["height" "1em !important"]
          ["padding" "0 !important"]
          ["margin" "0 !important"]
        ];
      }
      {
        select = "#urlbar[breakout][breakout-extend]";
        set = [
          ["position" "fixed !important"]
          ["inset-inline" "0 !important"]
          ["top" "var(--breakout-top) !important"]
          ["bottom" "auto !important"]
          ["transform" "none !important"]
          ["width" "var(--breakout-width) !important"]
          ["min-width" "min(600px, 90vw) !important"]
          ["max-width" "90vw !important"]
          ["height" "auto !important"]
          ["margin-block" "0 !important"]
          ["margin-inline" "auto !important"]
          ["padding" "0 !important"]
          ["border" "0 !important"]
          ["border-radius" "0 !important"]
          ["box-shadow" "none !important"]
          ["font-size" "calc(var(--chrome-font-size) * 1.25) !important"]
          ["z-index" "999 !important"]
        ];
      }
      {
        select = "#urlbar[breakout][breakout-extend] > .urlbar-background";
        set = [
          ["background-color" "var(--chrome-glass) !important"]
          ["backdrop-filter" "blur(24px) !important"]
          ["outline" "1px solid var(--chrome-line) !important"]
          ["outline-offset" "-1px !important"]
          ["border" "0 !important"]
          ["border-radius" "0 !important"]
        ];
      }
      {
        select = "#urlbar[breakout][breakout-extend] > .urlbar-input-container";
        set = [
          ["background" "transparent !important"]
          ["padding" "var(--bar-pad) 0 !important"]
          ["border" "0 !important"]
        ];
      }
      {
        select = "#urlbar-results, .search-one-offs, #urlbar-one-offs-container";
        set = [
          ["padding" "0 !important"]
          ["margin" "0 !important"]
          ["min-height" "0 !important"]
        ];
      }
      {
        select = ".urlbarView";
        set = [
          ["border-top" "1px solid var(--chrome-line) !important"]
          ["position" "absolute !important"]
          ["inset-inline" "0 !important"]
          ["top" "100% !important"]
          ["bottom" "auto !important"]
          ["width" "auto !important"]
          ["margin" "0 !important"]
          ["padding" "0 !important"]
          ["background-color" "var(--chrome-glass) !important"]
          ["backdrop-filter" "blur(24px) !important"]
          ["outline" "1px solid var(--chrome-line) !important"]
          ["outline-offset" "-1px !important"]
          ["border" "0 !important"]
          ["border-radius" "0 !important"]
          ["box-shadow" "none !important"]
          ["max-height" "calc(100vh - var(--breakout-top) - 3 * var(--bar-height)) !important"]
          ["overflow-y" "auto !important"]
          ["font-size" "var(--chrome-font-size) !important"]
        ];
      }
      {
        select = ".urlbarView-row";
        set = [
          ["min-height" "var(--urlbarview-row-min) !important"]
          ["padding" "0 !important"]
          ["margin" "0 !important"]
          ["border-radius" "0 !important"]
        ];
      }
      {
        select = ".urlbarView-row > .urlbarView-row-inner";
        set = [
          ["min-height" "var(--urlbarview-row-min) !important"]
          ["padding" "var(--urlbarview-row-pad) 0.5em !important"]
          ["align-items" "center !important"]
        ];
      }
      {
        select = ".urlbarView-favicon, .urlbarView-type-icon";
        set = [
          ["width" "1em !important"]
          ["height" "1em !important"]
          ["margin-inline-end" "0.4em !important"]
        ];
      }
      {
        select = ".urlbarView-url";
        set = [
          ["color" "var(--chrome-dim) !important"]
          ["margin-inline-start" "0.4em !important"]
        ];
      }
      {
        select = ".urlbarView-row[label]::before, .urlbarView-row[label] > .urlbarView-row-inner::before";
        set = [
          ["display" "none !important"]
        ];
      }
      {
        at = "@media (-moz-platform: linux)";
        rules = [
          {
            select = "#notification-popup, #permission-popup, #identity-popup, #protections-popup, #editBookmarkPanel, #appMenu-popup, #unified-extensions-panel, #downloadsPanel, #widget-overflow, #confirmation-hint, #customizationui-widget-panel:not(:has(#allTabsMenu-allTabsView))";
            set = [
              ["margin" "0 !important"]
              ["margin-bottom" "6px !important"]
              ["border-radius" "0 !important"]
              ["background-color" "var(--chrome-glass) !important"]
              ["backdrop-filter" "blur(24px) !important"]
              ["outline" "1px solid var(--chrome-line) !important"]
              ["outline-offset" "-1px !important"]
              ["box-shadow" "none !important"]
              ["font-size" "var(--chrome-font-size) !important"]
            ];
          }
          {
            select = "#appMenu-popup, #unified-extensions-panel, #downloadsPanel, #widget-overflow";
            set = [
              ["--panel-background" "transparent !important"]
            ];
          }
        ];
      }
      {
        select = ".panel-viewstack, .panel-viewcontainer";
        set = [
          ["background" "transparent !important"]
          ["border-radius" "0 !important"]
        ];
      }
      {
        select = ".panel-subview-body, .panel-header, .panel-footer";
        set = [
          ["padding" "0 !important"]
          ["border-radius" "0 !important"]
        ];
      }
      {
        select = ".panel-subview-body";
        set = [
          ["padding-block" "2px !important"]
        ];
      }
      {
        select = ".subviewbutton, .panel-banner-item, .toolbarbutton-1.subviewbutton";
        set = [
          ["min-height" "1.7em !important"]
          ["height" "auto !important"]
          ["padding" "0.1em 0.5em !important"]
          ["margin" "0 !important"]
          ["border-radius" "0 !important"]
        ];
      }
      {
        select = ".panel-header, .unified-extensions-item, .unified-extensions-item-row-wrapper";
        set = [
          ["min-height" "0 !important"]
          ["border-radius" "0 !important"]
        ];
      }
      {
        select = ".unified-extensions-item-name, .unified-extensions-item-message, .unified-extensions-item-message-deck";
        set = [
          ["line-height" "1.35 !important"]
          ["margin" "0 !important"]
          ["overflow" "hidden !important"]
          ["white-space" "nowrap !important"]
          ["text-overflow" "ellipsis !important"]
        ];
      }
      {
        select = ".subviewbutton > .menu-iconic-text, .subviewbutton > .toolbarbutton-text";
        set = [
          ["margin" "0 !important"]
        ];
      }
      {
        select = "toolbarseparator, .panel-separator, menuseparator";
        set = [
          ["border-top" "1px solid var(--chrome-line) !important"]
          ["border-bottom" "0 !important"]
          ["margin" "0.2em 0 !important"]
          ["padding" "0 !important"]
          ["height" "0 !important"]
        ];
      }
      {
        select = "menupopup";
        set = [
          ["appearance" "none !important"]
          ["border" "1px solid var(--chrome-line) !important"]
          ["border-radius" "0 !important"]
          ["background-color" "var(--chrome-field) !important"]
          ["color" "var(--chrome-text) !important"]
          ["max-height" "90vh !important"]
        ];
      }
      {
        select = "menupopup > menu, menupopup > menuitem";
        set = [
          ["appearance" "none !important"]
          ["padding" "0.15em 1em 0.15em 0.5em !important"]
          ["margin" "0 !important"]
          ["border-radius" "0 !important"]
        ];
      }
      {
        select = "menu, menuitem";
        set = [
          ["border-radius" "0 !important"]
          ["background-image" "none !important"]
        ];
      }
      {
        select = "menupopup > menu[_moz-menuactive]:not([disabled]), menupopup > menuitem[_moz-menuactive]:not([disabled]), menu[_moz-menuactive]:not([disabled]), menuitem[_moz-menuactive]:not([disabled])";
        set = [
          ["background-color" "var(--chrome-selected) !important"]
          ["color" "var(--chrome-text) !important"]
        ];
      }
      {
        select = ".menu-accel, .menu-iconic-accel";
        set = [
          ["color" "var(--chrome-dim) !important"]
          ["opacity" "1 !important"]
        ];
      }
      {
        select = "findbar";
        set = [
          ["width" "var(--bar-width) !important"]
          ["margin-inline" "auto !important"]
          ["border-top" "1px solid var(--chrome-line) !important"]
          ["height" "var(--bar-height) !important"]
          ["min-height" "0 !important"]
          ["padding" "0 !important"]
          ["border" "0 !important"]
          ["border-radius" "0 !important"]
          ["background" "transparent !important"]
          ["font-size" "var(--chrome-font-size) !important"]
        ];
      }
      {
        select = "findbar .findbar-container, findbar .findbar-textbox, findbar .findbar-find-status, findbar .found-matches, findbar .findbar-button";
        set = [
          ["height" "var(--bar-height) !important"]
          ["min-height" "0 !important"]
          ["padding" "0 var(--bar-pad) !important"]
          ["margin" "0 !important"]
          ["border-radius" "0 !important"]
          ["font-size" "var(--chrome-font-size) !important"]
        ];
      }
      {
        select = "findbar .findbar-textbox";
        set = [
          ["background-color" "var(--chrome-field) !important"]
          ["outline" "1px solid var(--chrome-line) !important"]
          ["outline-offset" "-1px !important"]
          ["border" "0 !important"]
        ];
      }
      {
        select = "findbar .findbar-checkbox, findbar .findbar-button";
        set = [
          ["padding" "0 0.4em !important"]
          ["border" "1px solid var(--chrome-line) !important"]
          ["height" "1.5em !important"]
          ["min-width" "0 !important"]
        ];
      }
      {
        select = "findbar .findbar-checkbox[checked='true'], findbar .findbar-button[checked='true']";
        set = [
          ["background-color" "var(--chrome-selected) !important"]
        ];
      }
      {
        select = "#context-navigation > menuitem";
        set = [
          ["padding" "0 !important"]
          ["min-height" "0 !important"]
        ];
      }
      {
        select = "#context-navigation image, #context-navigation .menu-iconic-icon";
        set = [
          ["width" "1.4em !important"]
          ["height" "1.4em !important"]
        ];
      }
      {
        select = "#unified-extensions-panel";
        set = [
          ["width" "32em !important"]
          ["max-width" "92vw !important"]
        ];
      }
      {
        select = "notification-message, #notifications-toolbar";
        set = [
          ["min-height" "0 !important"]
          ["font-size" "var(--chrome-font-size) !important"]
          ["border-radius" "0 !important"]
        ];
      }
      {
        at = "@media (prefers-reduced-motion: reduce)";
        rules = [
          {
            select = "*";
            set = [
              ["animation" "none !important"]
              ["transition" "none !important"]
              ["scroll-behavior" "auto !important"]
            ];
          }
        ];
      }
    ];
  };
}

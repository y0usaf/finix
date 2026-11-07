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

    "gfx.webrender.all" = true;
    "media.hardware-video-decoding.enabled" = true;
    "media.ffmpeg.vaapi.enabled" = false;
    "layers.acceleration.disabled" = false;

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
    ".config/glide"
    ".cache/librewolf"
    ".config/firefox"
    ".config/librewolf"
    ".librewolf"
    ".mozilla"
  ];
  environment.systemPackages = [
    (librewolfPkgs.librewolf-bin.override {
      extraPrefs =
        lib.concatMapAttrsStringSep "\n" (name: value: "lockPref(\"${name}\", ${builtins.toJSON value});") lockedPrefs
        + "\ndefaultPref(\"browser.display.use_document_fonts\", 0);";
      extraPolicies = policies // {DisableFirefoxAccounts = false;};
    })
    (pkgs.wrapFirefox (pkgs.callPackage "${flakeInputs.glide-browser}/package.nix" {}) {
      pname = "glide-browser";
      extraPrefs =
        lib.concatMapAttrsStringSep "\n" (name: value: "lockPref(\"${name}\", ${builtins.toJSON value});") (builtins.removeAttrs lockedPrefs ["browser.nova.enabled"])
        + "\ndefaultPref(\"browser.display.use_document_fonts\", 0);";
      extraPolicies =
        policies
        // {
          DisableFirefoxAccounts = false;
          ExtensionSettings = builtins.removeAttrs policies.ExtensionSettings ["vimium-c@gdh1995.cn"];
        };
    })
  ];
  user.files = {
    ".config/glide/glide/profiles.ini" = {
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
          ["--theme-frame" "var(--lwt-accent-color, light-dark(#ffffff, #000000))"]
          ["--theme-toolbar" "var(--toolbar-bgcolor, var(--theme-frame))"]
          ["--theme-tab-selected" "var(--lwt-selected-tab-background-color, var(--theme-toolbar))"]
          ["--theme-toolbar-field" "var(--toolbar-field-background-color, var(--theme-toolbar))"]
          ["--theme-tab-text" "var(--tab-text-color, var(--lwt-tab-text, light-dark(#000000, #ffffff)))"]
          ["--font-family" "monospace"]
          ["--chrome-font-size" "11px"]
          ["--bar-pad" "2px"]
          ["--bar-width" "75vw"]
          ["--bar-height" "calc(var(--chrome-font-size) + 2 * var(--bar-pad) + 2px)"]
          ["--breakout-width" "50vw"]
          ["--breakout-top" "20vh"]
          ["--popup-offset-top" "calc(var(--breakout-top) - 100vh)"]
          ["--tab-min-height" "var(--bar-height) !important"]
          ["--urlbar-min-height" "var(--bar-height) !important"]
          ["--urlbar-height" "var(--bar-height) !important"]
          ["--urlbar-container-height" "var(--bar-height) !important"]
          ["--toolbarbutton-inner-padding" "var(--bar-pad) !important"]
          ["--toolbarbutton-outer-padding" "0px !important"]
          ["--toolbar-start-end-padding" "0px !important"]
          ["--tab-block-margin" "0px !important"]
          ["--tab-inline-padding" "0.25em !important"]
          ["--urlbarview-row-pad" "0.35em"]
          ["--urlbarview-row-min" "calc(1.4em + 2 * var(--urlbarview-row-pad))"]
          ["--urlbarView-row-gutter" "0px !important"]
        ];
      }
      {
        select = "#TabsToolbar, #nav-bar, #titlebar";
        set = [
          ["font-size" "var(--chrome-font-size) !important"]
        ];
      }
      {
        select = "#navigator-toolbox";
        set = [
          ["display" "contents !important"]
        ];
      }
      {
        select = "#toolbar-menubar";
        set = [
          ["order" "-2 !important"]
        ];
      }
      {
        select = "#titlebar";
        set = [
          ["order" "-1 !important"]
          ["background-color" "var(--theme-frame) !important"]
          ["min-height" "var(--bar-height) !important"]
          ["max-height" "var(--bar-height) !important"]
        ];
      }
      {
        select = "#main-window > body > #browser";
        set = [
          ["order" "0 !important"]
        ];
      }
      {
        select = "#nav-bar";
        set = [
          ["order" "1 !important"]
          ["width" "var(--bar-width) !important"]
          ["height" "var(--bar-height) !important"]
          ["margin" "0 auto !important"]
          ["border" "0 !important"]
          ["background-color" "var(--theme-frame) !important"]
        ];
      }
      {
        select = "#nav-bar-customization-target";
        set = [
          ["min-width" "0 !important"]
        ];
      }
      {
        select = "#PersonalToolbar";
        set = [
          ["display" "none !important"]
        ];
      }
      {
        at = "@media (-moz-platform: linux)";
        rules = [
          {
            select = "#notification-popup[side=\"top\"], #permission-popup[side=\"top\"], #identity-popup[side=\"top\"], #protections-popup[side=\"top\"], #editBookmarkPanel[side=\"top\"], #appMenu-popup[side=\"top\"], #unified-extensions-panel[side=\"top\"], #downloadsPanel[side=\"top\"], #widget-overflow[side=\"top\"], #confirmation-hint[side=\"top\"], #customizationui-widget-panel[side=\"top\"]:not(:has(#allTabsMenu-allTabsView))";
            set = [
              ["margin-top" "var(--popup-offset-top) !important"]
            ];
          }
        ];
      }
      {
        select = ".panel-viewstack";
        set = [
          ["max-height" "calc(100vh - var(--breakout-top) - var(--bar-height) - 8px) !important"]
        ];
      }
      {
        select = "#TabsToolbar-customization-target, :root";
        set = [
          ["background-color" "var(--theme-frame) !important"]
        ];
      }
      {
        select = ":root, menupopup, panel, toolbar";
        set = [
          ["--panel-border-radius" "0px !important"]
          ["--arrowpanel-border-radius" "0px !important"]
          ["--toolbarbutton-border-radius" "0px !important"]
          ["--tab-border-radius" "0px !important"]
          ["--urlbar-border-radius" "0px !important"]
          ["--border-radius-small" "0px !important"]
          ["--border-radius-medium" "0px !important"]
          ["--border-radius-large" "0px !important"]
          ["--border-radius-xlarge" "0px !important"]
          ["--border-radius-xxlarge" "0px !important"]
          ["--button-border-radius" "0px !important"]
          ["--urlbarview-border-radius" "0px !important"]
          ["--urlbar-inner-border-radius" "0px !important"]
          ["--urlbarView-row-border-radius" "0px !important"]
          ["--urlbarView-icon-border-radius" "0px !important"]
          ["--urlbar-background-inset" "0px !important"]
        ];
      }
      {
        select = "#urlbar, .urlbar-background, .urlbar-input-container, .tab-background, .toolbarbutton-1, .urlbarView-row";
        set = [
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
      {
        select = "#statuspanel, .titlebar-buttonbox-container, .titlebar-spacer, .toolbar-spring, .urlbarView-row[label=\"LibreWolf Suggest\"], toolbarspring";
        set = [
          ["display" "none !important"]
        ];
      }
      {
        select = ":root:not([customizing]) #TabsToolbar";
        set = [
          ["margin" "0 auto !important"]
          ["width" "var(--bar-width) !important"]
          ["padding" "0 !important"]
          ["min-height" "0 !important"]
          ["max-height" "var(--bar-height) !important"]
          ["background-color" "var(--theme-frame) !important"]
        ];
      }
      {
        select = "#TabsToolbar, #titlebar, toolbar";
        set = [
          ["margin" "0 !important"]
          ["padding" "0 !important"]
        ];
      }
      {
        select = "#tabbrowser-arrowscrollbox, #tabbrowser-tabs, #tabbrowser-tabs > .tabbrowser-arrowscrollbox, .tabbrowser-tab";
        set = [
          ["min-height" "0 !important"]
        ];
      }
      {
        select = "#tabbrowser-arrowscrollbox:not([overflowing])";
        set = [
          ["--uc-flex-justify" "center !important"]
        ];
      }
      {
        select = "scrollbox[orient=\"horizontal\"] > slot";
        set = [
          ["justify-content" "var(--uc-flex-justify, initial) !important"]
        ];
      }
      {
        select = ".tabbrowser-tab";
        set = [
          ["height" "var(--bar-height) !important"]
          ["align-items" "center !important"]
          ["margin-bottom" "0 !important"]
          ["background-color" "var(--theme-frame) !important"]
        ];
      }
      {
        select = ".tabbrowser-tab .tab-content, .tabbrowser-tab .tab-background, .tabbrowser-tab .tab-stack";
        set = [
          ["margin" "0 !important"]
        ];
      }
      {
        select = ".tabbrowser-tab[selected=\"true\"], .tabbrowser-tab[selected=\"true\"] .tab-background, .tabbrowser-tab[visuallyselected=\"true\"], .tabbrowser-tab[visuallyselected=\"true\"] .tab-background";
        set = [
          ["background-color" "var(--theme-tab-selected) !important"]
        ];
      }
      {
        select = "#PersonalToolbar toolbarbutton, #TabsToolbar toolbarbutton, #nav-bar toolbarbutton, .toolbarbutton-1, toolbar .toolbarbutton-1, :root:not([customizing]) #TabsToolbar .titlebar-button, :root:not([customizing]) #tabbrowser-tabs .tabs-newtab-button, :root:not([customizing]) #tabs-newtab-button";
        set = [
          ["-moz-appearance" "none !important"]
          ["margin" "0 !important"]
          ["padding" "0 0.25em !important"]
        ];
      }
      {
        select = ".tab-icon-image, .toolbarbutton-icon, .urlbar-icon";
        set = [
          ["width" "1em !important"]
          ["height" "auto !important"]
          ["padding" "0 !important"]
        ];
      }
      {
        select = ".tab-icon-image";
        set = [
          ["margin-right" "0.3em !important"]
        ];
      }
      {
        select = "#urlbar-container";
        set = [
          ["font-family" "var(--font-family) !important"]
          ["margin" "0 !important"]
          ["padding" "0 !important"]
          ["z-index" "1 !important"]
        ];
      }
      {
        select = "#urlbar";
        set = [
          ["min-height" "var(--bar-height) !important"]
          ["border-color" "transparent !important"]
        ];
      }
      {
        select = "#urlbar:not([breakout-extend])";
        set = [
          ["height" "var(--bar-height) !important"]
        ];
      }
      {
        select = "#urlbar:not([breakout-extend]) > .urlbar-input-container";
        set = [
          ["height" "var(--bar-height) !important"]
          ["min-height" "var(--bar-height) !important"]
        ];
      }
      {
        select = "#urlbar-input";
        set = [
          ["margin" "0 0.5em !important"]
          ["text-align" "center !important"]
        ];
      }
      {
        select = "#urlbar > .urlbar-input-container";
        set = [
          ["padding" "0 !important"]
          ["border" "0 !important"]
        ];
      }
      {
        select = "#urlbar[breakout][breakout-extend]";
        set = [
          ["width" "var(--breakout-width) !important"]
          ["min-width" "min(600px, 90vw) !important"]
          ["top" "var(--breakout-top) !important"]
          ["left" "50% !important"]
          ["position" "fixed !important"]
          ["transform" "translateX(-50%) !important"]
          ["z-index" "999 !important"]
          ["margin" "0 !important"]
          ["box-shadow" "0 15px 30px rgba(0, 0, 0, 0.2) !important"]
          ["font-size" "calc(var(--chrome-font-size) * 1.3) !important"]
        ];
      }
      {
        select = "#urlbar[breakout][breakout-extend] > .urlbar-background, #urlbar[breakout][breakout-extend] > .urlbar-input-container";
        set = [
          ["background-color" "color-mix(in srgb, var(--theme-toolbar-field) 75%, transparent) !important"]
          ["backdrop-filter" "blur(30px) !important"]
          ["outline" "1px solid light-dark(rgba(20, 20, 20, 0.2), rgba(235, 235, 235, 0.2)) !important"]
          ["outline-offset" "-1px !important"]
        ];
      }
      {
        select = ".urlbarView";
        set = [
          ["max-height" "60vh !important"]
          ["overflow-y" "auto !important"]
          ["bottom" "100% !important"]
          ["top" "auto !important"]
        ];
      }
      {
        select = ".urlbarView-row";
        set = [
          ["min-height" "var(--urlbarview-row-min) !important"]
        ];
      }
      {
        select = ".urlbarView-row > .urlbarView-row-inner";
        set = [
          ["min-height" "var(--urlbarview-row-min) !important"]
          ["padding-block" "var(--urlbarview-row-pad) !important"]
          ["padding-inline" "0.5em !important"]
        ];
      }
      {
        select = ".urlbarView-row-inner *";
        set = [
          ["padding" "0 !important"]
          ["margin" "0 !important"]
        ];
      }
      {
        select = ".urlbarView-favicon";
        set = [
          ["margin-inline-end" "0.4em !important"]
        ];
      }
      {
        select = ":root[inFullscreen] #nav-bar";
        set = [
          ["display" "none !important"]
        ];
      }
    ];
  };
}

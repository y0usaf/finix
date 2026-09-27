{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  userName = config.user.name;
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
  finix.persistence.allowlist.users.${userName}.directories = [
    ".config/glide"
    ".cache/librewolf"
    ".config/librewolf"
    ".librewolf"
  ];
  environment.systemPackages = [
    (pkgs.librewolf-bin.override {
      extraPrefs =
        lib.concatMapAttrsStringSep "\n" (name: value: "lockPref(\"${name}\", ${builtins.toJSON value});") lockedPrefs
        + "\ndefaultPref(\"browser.display.use_document_fonts\", 0);";
      extraPolicies = policies // {DisableFirefoxAccounts = false;};
    })
    pkgs.pywalfox-native
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
  manzil.users."${userName}".files = {
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
    ".glide-browser/native-messaging-hosts/pywalfox.json" = {
      generator = lib.generators.toJSON {};
      value = {
        name = "pywalfox";
        description = "Native messaging host for Pywalfox";
        path = "${pkgs.writeShellScript "pywalfox-wrapper" ''
          exec ${pkgs.pywalfox-native}/bin/pywalfox start
        ''}";
        type = "stdio";
        allowed_extensions = ["pywalfox@frewacom.org"];
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
    ".librewolf/${userName}/chrome/userChrome.css".text = builtins.readFile ./userChrome.css;
    ".librewolf/native-messaging-hosts/pywalfox.json" = {
      generator = lib.generators.toJSON {};
      value = {
        name = "pywalfox";
        description = "Native messaging host for Pywalfox";
        path = "${pkgs.writeShellScript "pywalfox-wrapper" ''
          exec ${pkgs.pywalfox-native}/bin/pywalfox start
        ''}";
        type = "stdio";
        allowed_extensions = ["pywalfox@frewacom.org"];
      };
    };
  };
}

_: {
  browserPolicies = {
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
      "addon@darkreader.org" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
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
    };
  };
}

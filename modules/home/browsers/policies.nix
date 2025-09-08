{
  config,
  lib,
  ...
}: {
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
      # Vimium C
      "vimium-c@gdh1995.cn" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-c/latest.xpi";
        installation_mode = "force_installed";
        allowed_in_private_browsing = true;
      };
      # Violentmonkey
      "{aecec67f-0d10-4fa7-b7c7-609a2db280cf}" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/violentmonkey/latest.xpi";
        installation_mode = "force_installed";
        allowed_in_private_browsing = true;
      };
      # Twitch 5 (Alternate Player for Twitch.tv)
      "twitch5@coolcmd" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/twitch_5/latest.xpi";
        installation_mode = "force_installed";
        allowed_in_private_browsing = true;
      };
      # SponsorBlock
      "sponsorBlocker@ajay.app" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi";
        installation_mode = "force_installed";
        allowed_in_private_browsing = true;
      };
    };
    Preferences = {
      "toolkit.legacyUserProfileCustomizations.stylesheets" = {
        Value = true;
        Status = "locked";
      };
      # Dark theme
      "browser.theme.content-theme" = {
        Value = 0;
        Status = "locked";
      };
      "browser.theme.toolbar-theme" = {
        Value = 0;
        Status = "locked";
      };
      # Compact UI density
      "browser.uidensity" = {
        Value = 1;
        Status = "locked";
      };
      # Disable "Allow pages to choose their own fonts"
      "browser.display.use_document_fonts" = {
        Value = 0;
        Status = "default";
      };
      # Allow extensions to run
      "extensions.webextensions.restrictedDomains" = {
        Value = "";
        Status = "locked";
      };
      "extensions.webextensions.remote" = {
        Value = true;
        Status = "locked";
      };
      # Show separate titlebar by default
      "browser.tabs.drawInTitlebar" = {
        Value = true;
        Status = "locked";
      };
      # Hide bookmarks toolbar
      "browser.toolbars.bookmarks.visibility" = {
        Value = "never";
        Status = "locked";
      };
      # Performance settings from performance.nix
      "gfx.webrender.all" = {
        Value =
          if config.system.hardware.nvidia.enable or false
          then false
          else true;
        Status = "locked";
      };
      "media.hardware-video-decoding.enabled" = {
        Value =
          if config.system.hardware.nvidia.enable or false
          then false
          else true;
        Status = "locked";
      };
      "media.ffmpeg.vaapi.enabled" = {
        Value =
          if config.system.hardware.nvidia.enable or false
          then false
          else true;
        Status = "locked";
      };
      "layers.acceleration.disabled" = {
        Value =
          if config.system.hardware.nvidia.enable or false
          then true
          else false;
        Status = "locked";
      };
      "browser.sessionstore.interval" = {
        Value = 15000;
        Status = "locked";
      };
      "network.http.max-persistent-connections-per-server" = {
        Value = 10;
        Status = "locked";
      };
      "browser.cache.disk.enable" = {
        Value = false;
        Status = "locked";
      };
      "browser.cache.memory.enable" = {
        Value = true;
        Status = "locked";
      };
      "browser.cache.memory.capacity" = {
        Value = 1048576;
        Status = "locked";
      };
      "browser.sessionhistory.max_entries" = {
        Value = 50;
        Status = "locked";
      };
      "network.prefetch-next" = {
        Value = true;
        Status = "locked";
      };
      "network.dns.disablePrefetch" = {
        Value = false;
        Status = "locked";
      };
      "network.predictor.enabled" = {
        Value = true;
        Status = "locked";
      };
      "browser.enabledE10S" = {
        Value = false;
        Status = "locked";
      };
      "browser.theme.dark-private-windows" = {
        Value = false;
        Status = "locked";
      };
      "dom.webcomponents.enabled" = {
        Value = true;
        Status = "locked";
      };
      "layout.css.shadow-parts.enabled" = {
        Value = true;
        Status = "locked";
      };
      # Force individual extensions to work in private browsing
      "extensions.webextensions.uBlock0@raymondhill.net.privateBrowsingAllowed" = {
        Value = true;
        Status = "locked";
      };
      "extensions.webextensions.addon@darkreader.org.privateBrowsingAllowed" = {
        Value = true;
        Status = "locked";
      };
      "extensions.webextensions.vimium-c@gdh1995.cn.privateBrowsingAllowed" = {
        Value = true;
        Status = "locked";
      };
      "extensions.webextensions.{aecec67f-0d10-4fa7-b7c7-609a2db280cf}.privateBrowsingAllowed" = {
        Value = true;
        Status = "locked";
      };
      "extensions.webextensions.twitch5@coolcmd.privateBrowsingAllowed" = {
        Value = true;
        Status = "locked";
      };
      "extensions.webextensions.sponsorBlocker@ajay.app.privateBrowsingAllowed" = {
        Value = true;
        Status = "locked";
      };
    };
  };
}

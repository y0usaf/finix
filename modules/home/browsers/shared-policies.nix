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
    SkipOnboarding = true;
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
      # Font settings - force all fonts to use monospace
      "font.default.x-western" = {
        Value = "monospace";
        Status = "locked";
      };
      "font.name.sans-serif.x-western" = {
        Value = config.fonts.fontconfig.defaultFonts.monospace or ["monospace"];
        Status = "locked";
      };
      "font.name.serif.x-western" = {
        Value = config.fonts.fontconfig.defaultFonts.monospace or ["monospace"];
        Status = "locked";
      };
      "font.name.monospace.x-western" = {
        Value = config.fonts.fontconfig.defaultFonts.monospace or ["monospace"];
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
      # Show titlebar
      "browser.tabs.drawInTitlebar" = {
        Value = false;
        Status = "locked";
      };
      # Hide bookmarks toolbar
      "browser.toolbars.bookmarks.visibility" = {
        Value = "never";
        Status = "locked";
      };
    };
  };
}

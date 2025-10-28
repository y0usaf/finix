{
  config,
  lib,
}: let
  # Build font list from user config
  fontList = lib.concatStringsSep ", " [
    config.user.ui.fonts.mainFontName
    config.user.ui.fonts.backup.name
    "Symbols Nerd Font"
    config.user.ui.fonts.emoji.name
  ];
in {
  # Locked preferences (user cannot change)
  locked = {
    # Stylesheet support
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

    # Theme
    "browser.theme.content-theme" = 0;
    "browser.theme.toolbar-theme" = 0;
    "browser.uidensity" = 1;

    # Extensions
    "extensions.webextensions.remote" = true;

    # UI
    "browser.tabs.inTitlebar" = 0;
    "browser.toolbars.bookmarks.visibility" = "never";

    # Hardware acceleration (conditional on nvidia - not applicable on Darwin)
    "gfx.webrender.all" = true;
    "media.hardware-video-decoding.enabled" = true;
    "media.ffmpeg.vaapi.enabled" = false;
    "layers.acceleration.disabled" = false;

    # Performance
    "browser.sessionstore.interval" = 15000;
    "network.http.max-persistent-connections-per-server" = 10;
    "browser.cache.disk.enable" = false;
    "browser.cache.memory.enable" = true;
    "browser.cache.memory.capacity" = 1048576;
    "browser.sessionhistory.max_entries" = 50;
    "network.prefetch-next" = true;

    # Theme
    "browser.theme.dark-private-windows" = false;

    # Web components
    "dom.webcomponents.enabled" = true;
    "layout.css.shadow-parts.enabled" = true;

    # Disable ML features
    "browser.ml.enable" = false;
    "browser.ml.chat.enabled" = false;
    "extensions.ml.enabled" = false;
    "browser.ml.linkPreview.enabled" = false;
    "browser.tabs.groups.smart.enabled" = false;
    "browser.tabs.groups.smart.userEnabled" = false;

    # Privacy
    "privacy.resistFingerprinting" = false;

    # Font stack (pulled from user theme config)
    "font.name-list.monospace.x-unicode" = fontList;
    "font.name-list.monospace.x-western" = fontList;
    "font.name-list.sans-serif.x-unicode" = fontList;
    "font.name-list.sans-serif.x-western" = fontList;
    "font.name-list.serif.x-unicode" = fontList;
    "font.name-list.serif.x-western" = fontList;
  };

  # Default preferences (user can override)
  default = {
    "browser.display.use_document_fonts" = 0;
  };
}

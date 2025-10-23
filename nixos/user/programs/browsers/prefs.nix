{
  config,
  lib,
}: let
  # Build font list from user appearance config
  fontList = lib.concatStringsSep ", " (
    [(builtins.elemAt config.user.appearance.fonts.main 0).name]
    ++ map (f: f.name) config.user.appearance.fonts.fallback
  );
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

    # Hardware acceleration (conditional on nvidia)
    "gfx.webrender.all" =
      if config.system.hardware.nvidia.enable or false
      then false
      else true;
    "media.hardware-video-decoding.enabled" =
      if config.system.hardware.nvidia.enable or false
      then false
      else true;
    "media.ffmpeg.vaapi.enabled" =
      if config.system.hardware.nvidia.enable or false
      then false
      else true;
    "layers.acceleration.disabled" =
      if config.system.hardware.nvidia.enable or false
      then true
      else false;

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

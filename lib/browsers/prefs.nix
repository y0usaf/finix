{
  config,
  lib,
}: let
  fontList = lib.concatStringsSep ", " [
    config.user.ui.fonts.mainFontName
    config.user.ui.fonts.backup.name
    "Symbols Nerd Font"
    config.user.ui.fonts.emoji.name
  ];
in {
  locked = {
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

    "browser.theme.content-theme" = 0;
    "browser.theme.toolbar-theme" = 0;
    "browser.uidensity" = 1;

    "extensions.webextensions.remote" = true;

    "browser.tabs.inTitlebar" = 0;
    "browser.toolbars.bookmarks.visibility" = "never";

    "gfx.webrender.all" = config.user.programs.browser.hardwareAccel.webrender or true;
    "media.hardware-video-decoding.enabled" = config.user.programs.browser.hardwareAccel.videoDecoding or true;
    "media.ffmpeg.vaapi.enabled" = config.user.programs.browser.hardwareAccel.vaapi or false;
    "layers.acceleration.disabled" = config.user.programs.browser.hardwareAccel.disabled or false;

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

  default = {
    "browser.display.use_document_fonts" = 0;
  };
}

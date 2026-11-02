{
  config,
  lib,
  ...
}: let
  browser = "${config.user.defaults.browser}.desktop";
  web = ["text/html" "x-scheme-handler/http" "x-scheme-handler/https" "x-scheme-handler/ftp"];
  handledBy = app: types: lib.genAttrs types (_: app);
in {
  manzil.users.${config.user.name}.files.".config/mimeapps.list" = {
    generator = lib.generators.toINI {};
    value = {
      "Default Applications" =
        handledBy browser (web
          ++ [
            "x-scheme-handler/chrome"
            "application/x-extension-htm"
            "application/x-extension-html"
            "application/x-extension-shtml"
            "application/xhtml+xml"
            "application/x-extension-xhtml"
          ])
        // handledBy "discord.desktop" ["x-scheme-handler/discord"]
        // handledBy "pcmanfm.desktop" ["inode/directory"]
        // handledBy "mpv.desktop" ["video/mp4" "video/x-matroska" "video/webm"]
        // handledBy "imv.desktop" ["image/jpeg" "image/png" "image/gif" "image/tiff" "image/bmp"]
        // handledBy "file-roller.desktop" ["application/zip" "application/x-7z-compressed" "application/x-tar" "application/gzip" "application/x-compressed-tar"];
      "Added Associations" = handledBy browser web;
    };
  };
}

{
  config,
  lib,
  ...
}: {
  options.home.programs.mimeapps = {
    enable = lib.mkEnableOption "XDG mime applications associations";
  };

  config = {
    usr.files = {
      ".config/mimeapps.list" = {
        clobber = true;
        text = ''
          [Default Applications]
          text/html=${config.home.core.defaults.browser}.desktop
          x-scheme-handler/http=${config.home.core.defaults.browser}.desktop
          x-scheme-handler/https=${config.home.core.defaults.browser}.desktop
          x-scheme-handler/ftp=${config.home.core.defaults.browser}.desktop
          x-scheme-handler/chrome=${config.home.core.defaults.browser}.desktop
          x-scheme-handler/discord=${config.home.core.defaults.discord}.desktop
          inode/directory=${config.home.core.defaults.fileManager}.desktop
          video/mp4=${config.home.core.defaults.mediaPlayer}.desktop
          video/x-matroska=${config.home.core.defaults.mediaPlayer}.desktop
          video/webm=${config.home.core.defaults.mediaPlayer}.desktop
          image/jpeg=${config.home.core.defaults.imageViewer}.desktop
          image/png=${config.home.core.defaults.imageViewer}.desktop
          image/gif=${config.home.core.defaults.imageViewer}.desktop
          image/tiff=${config.home.core.defaults.imageViewer}.desktop
          image/bmp=${config.home.core.defaults.imageViewer}.desktop
          application/zip=${config.home.core.defaults.archiveManager}.desktop
          application/x-7z-compressed=${config.home.core.defaults.archiveManager}.desktop
          application/x-tar=${config.home.core.defaults.archiveManager}.desktop
          application/gzip=${config.home.core.defaults.archiveManager}.desktop
          application/x-compressed-tar=${config.home.core.defaults.archiveManager}.desktop
          application/x-extension-htm=${config.home.core.defaults.browser}.desktop
          application/x-extension-html=${config.home.core.defaults.browser}.desktop
          application/x-extension-shtml=${config.home.core.defaults.browser}.desktop
          application/xhtml+xml=${config.home.core.defaults.browser}.desktop
          application/x-extension-xhtml=${config.home.core.defaults.browser}.desktop
          [Added Associations]
          text/html=${config.home.core.defaults.browser}.desktop
          x-scheme-handler/http=${config.home.core.defaults.browser}.desktop
          x-scheme-handler/https=${config.home.core.defaults.browser}.desktop
          x-scheme-handler/ftp=${config.home.core.defaults.browser}.desktop
        '';
      };
    };
  };
}

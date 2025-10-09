{
  config,
  lib,
  ...
}: {
  options.user.programs.mimeapps = {
    enable = lib.mkEnableOption "XDG mime applications associations";
  };

  config = {
    usr.files = {
      ".config/mimeapps.list" = {
        clobber = true;
        text = ''
          [Default Applications]
          text/html=${config.user.core.defaults.browser}.desktop
          x-scheme-handler/http=${config.user.core.defaults.browser}.desktop
          x-scheme-handler/https=${config.user.core.defaults.browser}.desktop
          x-scheme-handler/ftp=${config.user.core.defaults.browser}.desktop
          x-scheme-handler/chrome=${config.user.core.defaults.browser}.desktop
          x-scheme-handler/discord=${config.user.core.defaults.discord}.desktop
          inode/directory=${config.user.core.defaults.fileManager}.desktop
          video/mp4=${config.user.core.defaults.mediaPlayer}.desktop
          video/x-matroska=${config.user.core.defaults.mediaPlayer}.desktop
          video/webm=${config.user.core.defaults.mediaPlayer}.desktop
          image/jpeg=${config.user.core.defaults.imageViewer}.desktop
          image/png=${config.user.core.defaults.imageViewer}.desktop
          image/gif=${config.user.core.defaults.imageViewer}.desktop
          image/tiff=${config.user.core.defaults.imageViewer}.desktop
          image/bmp=${config.user.core.defaults.imageViewer}.desktop
          application/zip=${config.user.core.defaults.archiveManager}.desktop
          application/x-7z-compressed=${config.user.core.defaults.archiveManager}.desktop
          application/x-tar=${config.user.core.defaults.archiveManager}.desktop
          application/gzip=${config.user.core.defaults.archiveManager}.desktop
          application/x-compressed-tar=${config.user.core.defaults.archiveManager}.desktop
          application/x-extension-htm=${config.user.core.defaults.browser}.desktop
          application/x-extension-html=${config.user.core.defaults.browser}.desktop
          application/x-extension-shtml=${config.user.core.defaults.browser}.desktop
          application/xhtml+xml=${config.user.core.defaults.browser}.desktop
          application/x-extension-xhtml=${config.user.core.defaults.browser}.desktop
          [Added Associations]
          text/html=${config.user.core.defaults.browser}.desktop
          x-scheme-handler/http=${config.user.core.defaults.browser}.desktop
          x-scheme-handler/https=${config.user.core.defaults.browser}.desktop
          x-scheme-handler/ftp=${config.user.core.defaults.browser}.desktop
        '';
      };
    };
  };
}

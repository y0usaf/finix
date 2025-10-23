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
          text/html=${config.user.defaults.browser}.desktop
          x-scheme-handler/http=${config.user.defaults.browser}.desktop
          x-scheme-handler/https=${config.user.defaults.browser}.desktop
          x-scheme-handler/ftp=${config.user.defaults.browser}.desktop
          x-scheme-handler/chrome=${config.user.defaults.browser}.desktop
          x-scheme-handler/discord=${config.user.defaults.discord}.desktop
          inode/directory=${config.user.defaults.fileManager}.desktop
          video/mp4=${config.user.defaults.mediaPlayer}.desktop
          video/x-matroska=${config.user.defaults.mediaPlayer}.desktop
          video/webm=${config.user.defaults.mediaPlayer}.desktop
          image/jpeg=${config.user.defaults.imageViewer}.desktop
          image/png=${config.user.defaults.imageViewer}.desktop
          image/gif=${config.user.defaults.imageViewer}.desktop
          image/tiff=${config.user.defaults.imageViewer}.desktop
          image/bmp=${config.user.defaults.imageViewer}.desktop
          application/zip=${config.user.defaults.archiveManager}.desktop
          application/x-7z-compressed=${config.user.defaults.archiveManager}.desktop
          application/x-tar=${config.user.defaults.archiveManager}.desktop
          application/gzip=${config.user.defaults.archiveManager}.desktop
          application/x-compressed-tar=${config.user.defaults.archiveManager}.desktop
          application/x-extension-htm=${config.user.defaults.browser}.desktop
          application/x-extension-html=${config.user.defaults.browser}.desktop
          application/x-extension-shtml=${config.user.defaults.browser}.desktop
          application/xhtml+xml=${config.user.defaults.browser}.desktop
          application/x-extension-xhtml=${config.user.defaults.browser}.desktop
          [Added Associations]
          text/html=${config.user.defaults.browser}.desktop
          x-scheme-handler/http=${config.user.defaults.browser}.desktop
          x-scheme-handler/https=${config.user.defaults.browser}.desktop
          x-scheme-handler/ftp=${config.user.defaults.browser}.desktop
        '';
      };
    };
  };
}

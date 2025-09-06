{
  config,
  lib,
  ...
}: let
  cfg = config.home.programs.mimeapps;
in {
  options.home.programs.mimeapps = {
    enable = lib.mkEnableOption "XDG mime applications associations";
  };

  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name}.files = {
      ".config/mimeapps.list" = {
        clobber = true;
        text = ''
          [Default Applications]
          text/html=${config.core.defaults.browser}.desktop
          x-scheme-handler/http=${config.core.defaults.browser}.desktop
          x-scheme-handler/https=${config.core.defaults.browser}.desktop
          x-scheme-handler/ftp=${config.core.defaults.browser}.desktop
          x-scheme-handler/chrome=${config.core.defaults.browser}.desktop
          x-scheme-handler/discord=${config.core.defaults.discord}.desktop
          inode/directory=${config.core.defaults.fileManager}.desktop
          video/mp4=${config.core.defaults.mediaPlayer}.desktop
          video/x-matroska=${config.core.defaults.mediaPlayer}.desktop
          video/webm=${config.core.defaults.mediaPlayer}.desktop
          image/jpeg=${config.core.defaults.imageViewer}.desktop
          image/png=${config.core.defaults.imageViewer}.desktop
          image/gif=${config.core.defaults.imageViewer}.desktop
          image/tiff=${config.core.defaults.imageViewer}.desktop
          image/bmp=${config.core.defaults.imageViewer}.desktop
          application/zip=${config.core.defaults.archiveManager}.desktop
          application/x-7z-compressed=${config.core.defaults.archiveManager}.desktop
          application/x-tar=${config.core.defaults.archiveManager}.desktop
          application/gzip=${config.core.defaults.archiveManager}.desktop
          application/x-compressed-tar=${config.core.defaults.archiveManager}.desktop
          application/x-extension-htm=${config.core.defaults.browser}.desktop
          application/x-extension-html=${config.core.defaults.browser}.desktop
          application/x-extension-shtml=${config.core.defaults.browser}.desktop
          application/xhtml+xml=${config.core.defaults.browser}.desktop
          application/x-extension-xhtml=${config.core.defaults.browser}.desktop
          [Added Associations]
          text/html=${config.core.defaults.browser}.desktop
          x-scheme-handler/http=${config.core.defaults.browser}.desktop
          x-scheme-handler/https=${config.core.defaults.browser}.desktop
          x-scheme-handler/ftp=${config.core.defaults.browser}.desktop
        '';
      };
    };
  };
}

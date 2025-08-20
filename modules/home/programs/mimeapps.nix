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
          text/html=firefox.desktop
          x-scheme-handler/http=firefox.desktop
          x-scheme-handler/https=firefox.desktop
          x-scheme-handler/ftp=firefox.desktop
          x-scheme-handler/chrome=firefox.desktop
          x-scheme-handler/discord=discord.desktop
          inode/directory=pcmanfm.desktop
          video/mp4=mpv.desktop
          video/x-matroska=mpv.desktop
          video/webm=mpv.desktop
          image/jpeg=imv.desktop
          image/png=imv.desktop
          image/gif=imv.desktop
          image/tiff=imv.desktop
          image/bmp=imv.desktop
          application/zip=file-roller.desktop
          application/x-7z-compressed=file-roller.desktop
          application/x-tar=file-roller.desktop
          application/gzip=file-roller.desktop
          application/x-compressed-tar=file-roller.desktop
          application/x-extension-htm=firefox.desktop
          application/x-extension-html=firefox.desktop
          application/x-extension-shtml=firefox.desktop
          application/xhtml+xml=firefox.desktop
          application/x-extension-xhtml=firefox.desktop
          [Added Associations]
          text/html=firefox.desktop
          x-scheme-handler/http=firefox.desktop
          x-scheme-handler/https=firefox.desktop
          x-scheme-handler/ftp=firefox.desktop
        '';
      };
    };
  };
}

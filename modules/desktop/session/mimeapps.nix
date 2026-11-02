{config, ...}: let
  browser = "${config.user.defaults.browser}.desktop";
in {
  manzil.users.${config.user.name}.files = {
    ".config/mimeapps.list" = {
      text = ''
        [Default Applications]
        text/html=${browser}
        x-scheme-handler/http=${browser}
        x-scheme-handler/https=${browser}
        x-scheme-handler/ftp=${browser}
        x-scheme-handler/chrome=${browser}
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
        application/x-extension-htm=${browser}
        application/x-extension-html=${browser}
        application/x-extension-shtml=${browser}
        application/xhtml+xml=${browser}
        application/x-extension-xhtml=${browser}
        [Added Associations]
        text/html=${browser}
        x-scheme-handler/http=${browser}
        x-scheme-handler/https=${browser}
        x-scheme-handler/ftp=${browser}
      '';
    };
  };
}

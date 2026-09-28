{config, ...}: {
  manzil.users."${config.user.name}".files = {
    ".config/mimeapps.list" = {
      text = ''
        [Default Applications]
        text/html=${config.user.defaults.browser}.desktop
        x-scheme-handler/http=${config.user.defaults.browser}.desktop
        x-scheme-handler/https=${config.user.defaults.browser}.desktop
        x-scheme-handler/ftp=${config.user.defaults.browser}.desktop
        x-scheme-handler/chrome=${config.user.defaults.browser}.desktop
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
}

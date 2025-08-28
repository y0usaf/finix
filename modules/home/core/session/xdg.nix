{
  config,
  lib,
  ...
}: {
  config = {
    hjem.users.${config.user.name}.files = {
      ".config/zsh/.zshenv" = {
        clobber = true;
        text = lib.mkAfter ''
          # Custom XDG directories for desktop integration
          export XDG_SCREENSHOTS_DIR="$HOME/Pictures/Screenshots"
          export XDG_WALLPAPERS_DIR="$HOME/Pictures/Wallpapers"
        '';
      };
      ".config/user-dirs.dirs" = {
        clobber = true;
        text = ''
          XDG_DESKTOP_DIR="${config.user.homeDirectory}/Desktop"
          XDG_DOWNLOAD_DIR="${config.user.homeDirectory}/Downloads"
          XDG_TEMPLATES_DIR="${config.user.homeDirectory}/Templates"
          XDG_PUBLICSHARE_DIR="${config.user.homeDirectory}/Public"
          XDG_DOCUMENTS_DIR="${config.user.homeDirectory}/Documents"
          XDG_MUSIC_DIR="${config.user.homeDirectory}/Music"
          XDG_PICTURES_DIR="${config.user.homeDirectory}/Pictures"
          XDG_VIDEOS_DIR="${config.user.homeDirectory}/Videos"
          XDG_SCREENSHOTS_DIR="${config.user.homeDirectory}/Pictures/Screenshots"
          XDG_WALLPAPERS_DIR="${config.user.homeDirectory}/Pictures/Wallpapers"
        '';
      };
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
      ".local/share/applications/firefox.desktop" = {
        clobber = true;
        text = ''
          [Desktop Entry]
          Name=Firefox
          GenericName=Web Browser
          Exec=firefox %U
          Terminal=false
          Type=Application
          Categories=Application;Network;WebBrowser;
          MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;
          Icon=firefox
          StartupNotify=true
        '';
      };
    };
  };
}

{config, ...}: {
  config = {
    usr.files = {
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
    };
  };
}

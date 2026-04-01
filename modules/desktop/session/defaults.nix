{lib, ...}: {
  options.user.defaults = {
    ide = lib.mkOption {
      type = lib.types.str;
      default = "cursor";
      description = "Default IDE";
    };
    fileManager = lib.mkOption {
      type = lib.types.str;
      default = "pcmanfm";
      description = "Default file manager";
    };
    launcher = lib.mkOption {
      type = lib.types.str;
      default = "foot -a 'launcher' ~/.config/scripts/tui-launcher.sh";
      description = "Default application launcher";
    };
    discord = lib.mkOption {
      type = lib.types.str;
      default = "discord-canary";
      description = "Default Discord client";
    };
    archiveManager = lib.mkOption {
      type = lib.types.str;
      default = "file-roller";
      description = "Default archive manager";
    };
    imageViewer = lib.mkOption {
      type = lib.types.str;
      default = "imv";
      description = "Default image viewer";
    };
    mediaPlayer = lib.mkOption {
      type = lib.types.str;
      default = "mpv";
      description = "Default media player";
    };
  };
}

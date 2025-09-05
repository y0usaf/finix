{
  config,
  lib,
  ...
}: {
  options.home.core.defaults = {
    browser = lib.mkOption {
      type = lib.types.str;
      default = "firefox";
      description = "Default web browser";
    };
    editor = lib.mkOption {
      type = lib.types.str;
      description = "Default text editor";
    };
    ide = lib.mkOption {
      type = lib.types.str;
      description = "Default IDE";
    };
    terminal = lib.mkOption {
      type = lib.types.str;
      description = "Default terminal emulator";
    };
    fileManager = lib.mkOption {
      type = lib.types.str;
      description = "Default file manager";
    };
    launcher = lib.mkOption {
      type = lib.types.str;
      description = "Default application launcher";
    };
    discord = lib.mkOption {
      type = lib.types.str;
      description = "Default Discord client";
    };
    archiveManager = lib.mkOption {
      type = lib.types.str;
      description = "Default archive manager";
    };
    imageViewer = lib.mkOption {
      type = lib.types.str;
      description = "Default image viewer";
    };
    mediaPlayer = lib.mkOption {
      type = lib.types.str;
      description = "Default media player";
    };
  };
  config = {
  };
}

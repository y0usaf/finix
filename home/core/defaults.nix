###############################################################################
# Default Applications Module
# Default application settings for desktop integration
###############################################################################
{
  config,
  lib,
  ...
}: {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.core.defaults = {
    browser = lib.mkOption {
      type = lib.types.str;
      default = "firefox";
      description = "Default web browser";
    };

    editor = lib.mkOption {
      type = lib.types.str;
      default = "nvim";
      description = "Default text editor";
    };

    ide = lib.mkOption {
      type = lib.types.str;
      default = "cursor";
      description = "Default IDE";
    };

    terminal = lib.mkOption {
      type = lib.types.str;
      default = "foot";
      description = "Default terminal emulator";
    };

    fileManager = lib.mkOption {
      type = lib.types.str;
      default = "pcmanfm";
      description = "Default file manager";
    };

    launcher = lib.mkOption {
      type = lib.types.str;
      default = "foot -a 'launcher' $HOME/.config/scripts/sway-launcher-desktop.sh";
      description = "Default application launcher";
    };

    discord = lib.mkOption {
      type = lib.types.str;
      default = "discord-canary";
      description = "Default Discord client";
    };

    archiveManager = lib.mkOption {
      type = lib.types.str;
      default = "7z";
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

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = {
    # No packages or files needed - this is just option definitions
  };
}

{lib, ...}: {
  options.user = {
    packages = {
      extraPackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [];
        description = "Additional packages to install system-wide";
      };
    };

    terminal = {
      alacritty = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Alacritty terminal emulator";
        };
      };
    };

    wm = {
      aerospace = {
        enable = lib.mkEnableOption "AeroSpace tiling window manager";
      };
    };

    tools = {
      raycast = {
        enable = lib.mkEnableOption "Raycast launcher and AI assistant";
      };

      karabiner = {
        enable = lib.mkEnableOption "Karabiner-Elements keyboard remapper";
      };
    };

    ui = {
      fonts = {
        mainFontName = lib.mkOption {
          type = lib.types.str;
          default = "Iosevka Term Slab";
          description = "Main font family name";
        };
        backup = lib.mkOption {
          type = lib.types.submodule {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                default = "DejaVu Sans Mono";
                description = "Backup font family name";
              };
            };
          };
          default = {};
          description = "Backup font configuration";
        };
        emoji = lib.mkOption {
          type = lib.types.submodule {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                default = "Noto Color Emoji";
                description = "Emoji font family name";
              };
            };
          };
          default = {};
          description = "Emoji font configuration";
        };
      };
    };
  };
}

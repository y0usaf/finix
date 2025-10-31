{lib, ...}: {
  options.user = {
    packages = {
      extraPackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [];
      };
    };

    terminal = {
      alacritty = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
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
        };
        backup = lib.mkOption {
          type = lib.types.submodule {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                default = "DejaVu Sans Mono";
              };
            };
          };
          default = {};
        };
        emoji = lib.mkOption {
          type = lib.types.submodule {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                default = "Noto Color Emoji";
              };
            };
          };
          default = {};
        };
      };
    };
  };
}

{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.ui.gtk;
  mainFontName = (builtins.elemAt config.home.core.appearance.fonts.main 0).name;
  inherit (config.home.core.appearance) baseFontSize;
  dpiStr = toString config.home.core.appearance.dpi;
  inherit (config.home.core.user) bookmarks;
  scaleFactor = cfg.scale;
  shadowSize = "0.05rem";
  shadowRadius = "0.05rem";
  shadowColor = "rgba(0, 0, 0, 0.3)";
  shadowOffsets = [
    "${shadowSize} 0 ${shadowRadius} ${shadowColor}"
    "-${shadowSize} 0 ${shadowRadius} ${shadowColor}"
    "0 ${shadowSize} ${shadowRadius} ${shadowColor}"
    "0 -${shadowSize} ${shadowRadius} ${shadowColor}"
    "${shadowSize} ${shadowSize} ${shadowRadius} ${shadowColor}"
    "-${shadowSize} ${shadowSize} ${shadowRadius} ${shadowColor}"
    "${shadowSize} -${shadowSize} ${shadowRadius} ${shadowColor}"
    "-${shadowSize} -${shadowSize} ${shadowRadius} ${shadowColor}"
  ];
  repeatedShadow = lib.concatStringsSep ",\n" (lib.concatLists (lib.genList (_: shadowOffsets) 4));
  whiteColor = "white";
  transparentColor = "transparent";
  menuBackground = "rgba(0, 0, 0, 0.8)";
  hoverBg = "rgba(100, 149, 237, 0.1)";
  selectedBg = "rgba(100, 149, 237, 0.5)";
  gtk3Settings = {
    Settings = {
      gtk-application-prefer-dark-theme = 1;
      gtk-cursor-theme-name = "DeepinDarkV20-x11";
      gtk-cursor-theme-size = toString (builtins.floor (24 * scaleFactor));
      gtk-font-name = "${mainFontName} ${toString baseFontSize}";
      gtk-xft-antialias = 1;
      gtk-xft-dpi = dpiStr;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintslight";
      gtk-xft-rgba = "rgb";
    };
  };
  gtk4Settings = {
    Settings = {
      gtk-application-prefer-dark-theme = 1;
      gtk-cursor-theme-name = "DeepinDarkV20-x11";
      gtk-cursor-theme-size = toString (builtins.floor (24 * scaleFactor));
      gtk-font-name = "${mainFontName} ${toString baseFontSize}";
    };
  };
  gtkCss = ''
    /* Global element styling */
    * {
      font-family: "${mainFontName}";
      color: ${whiteColor};
      background: ${transparentColor};
      outline-width: 0;
      outline-offset: 0;
      text-shadow: ${repeatedShadow};
    }
    /* Hover state for all elements */
    *:hover {
      background: ${hoverBg};
    }
    /* Selected state for all elements */
    *:selected {
      background: ${selectedBg};
    }
    /* Button styling */
    button {
      border-radius: 0.15rem;
      min-height: 1rem;
      padding: 0.05rem 0.25rem;
    }
    /* Menu background styling */
    menu {
      background: ${menuBackground};
    }
  '';
  bookmarksContent = lib.concatStringsSep "\n" bookmarks;
in {
  options.home.ui.gtk = {
    enable = lib.mkEnableOption "GTK theming and configuration using nix-maid";
    scale = lib.mkOption {
      type = lib.types.float;
      default = 1.0;
      description = "Scaling factor for GTK applications (e.g., 1.0, 1.25, 1.5, 2.0)";
      example = 1.5;
    };
  };
  config = lib.mkIf cfg.enable {
    users.users.y0usaf.maid = {
      packages = with pkgs; [
        gtk3
        gtk4
      ];
      file = {
        xdg_config = {
          "gtk-3.0/settings.ini".text = lib.generators.toINI {} gtk3Settings;
          "gtk-3.0/gtk.css".text = gtkCss;
          "gtk-3.0/bookmarks".text = bookmarksContent;
          "gtk-4.0/settings.ini".text = lib.generators.toINI {} gtk4Settings;
        };
        home.".zshenv".text = lib.mkAfter ''
          export XCURSOR_SIZE="${builtins.replaceStrings [".0"] [""] (toString (builtins.floor (24 * scaleFactor)))}"
        '';
      };
    };
  };
}

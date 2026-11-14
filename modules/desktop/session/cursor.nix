{
  config,
  lib,
  pkgs,
  inputPackages,
  ...
}: let
  variants = {
    dark = inputPackages.cursors.pixel-dark;
    light = inputPackages.cursors.pixel-light;
  };

  iconTheme = variant: "${variant}/share/icons/${variant.xcursorThemeName}";

  fallback = pkgs.runCommand "pixel-cursor-fallback" {} ''
    mkdir -p $out/share/icons
    ln -s ${iconTheme variants.dark} $out/share/icons/${config.user.appearance.cursorTheme}
  '';

  cursorApply = pkgs.writeShellApplication {
    name = "cursor-apply";
    runtimeInputs = [pkgs.coreutils pkgs.dconf];
    text = ''
      case "''${1:-}" in
        light)
          target=${iconTheme variants.light}
          theme=${variants.light.xcursorThemeName}
          ;;
        dark)
          target=${iconTheme variants.dark}
          theme=${variants.dark.xcursorThemeName}
          ;;
        *)
          echo "usage: cursor-apply <light|dark>" >&2
          exit 1
          ;;
      esac
      data="''${XDG_DATA_HOME:-$HOME/.local/share}"
      mkdir -p "$data/icons"
      ln -sfn "$target" "$data/icons/${config.user.appearance.cursorTheme}"
      dconf write /org/gnome/desktop/interface/cursor-theme "'$theme'"
      dconf write /org/gnome/desktop/interface/cursor-size ${toString config.user.appearance.cursorSize}
    '';
  };
in {
  options.user.appearance.cursorTheme = lib.mkOption {
    type = lib.types.str;
    default = "Pixel-Cursor";
    description = "Stable Xcursor theme name the session resolves; cursor-apply repoints it at the light or dark pixel cursor variant, so running clients keep one name and pick up the active variant.";
  };

  options.user.appearance.cursorSize = lib.mkOption {
    type = lib.types.int;
    default = 32;
    description = "Nominal Xcursor size in pixels; the pixel cursor themes draw at 23 px inside this canvas.";
  };

  options.user.appearance.hyprcursorSize = lib.mkOption {
    type = lib.types.int;
    default = 24;
    description = "Base Hyprcursor size at user.appearance.dpi.";
  };

  options.user.appearance.applyCursor = lib.mkOption {
    type = lib.types.functionTo lib.types.str;
    readOnly = true;
    default = mode:
      if variants ? ${mode}
      then "${lib.getExe cursorApply} ${mode}"
      else throw "user.appearance.applyCursor: no cursor variant named ${mode}; there is light and dark";
    description = "The command that points the session cursor at the light or dark pixel cursor variant: it repoints the stable theme name that Tomoe, GTK and Xwayland resolve at the active variant's files and sets the cursor theme and size that GTK apps follow live.";
  };

  config.environment = {
    systemPackages = [variants.dark variants.light fallback];
    variables = {
      XCURSOR_THEME = config.user.appearance.cursorTheme;
      XCURSOR_SIZE = toString config.user.appearance.cursorSize;
      HYPRCURSOR_THEME = config.user.appearance.cursorTheme;
      HYPRCURSOR_SIZE = toString config.user.appearance.hyprcursorSize;
    };
  };
}

###############################################################################
# Kitty Terminal Configuration
# Fast, feature-rich terminal emulator with GPU acceleration
# - Terminal styling and appearance
# - Key bindings for clipboard operations
# - Font configuration with fallback support
# - Cursor and mouse behavior settings
###############################################################################
{
  config,
  lib,
  hostHome,
  ...
}: let
  cfg = config.cfg.ui.kitty;

  # Calculate the scaled font size based on the hostHome's base font size.
  computedFontSize = hostHome.cfg.appearance.baseFontSize * 1.33;

  # Get the main font name from the hostHome's font configuration
  mainFontName = (builtins.elemAt hostHome.cfg.appearance.fonts.main 0).name;



  # Note: Kitty handles font fallbacks automatically, so we don't need explicit symbol_map

  # Main terminal settings
  kittyMainSettings = {
    # Terminal identification
    term = "xterm-256color";

    # Font configuration - Note: font_family and font_size are handled by the font attribute
    # so we don't set them in settings to avoid conflicts

    # Cursor settings - equivalent to Foot's underline style and no blink
    cursor_shape = "underline";
    cursor_blink_interval = "0"; # 0 disables blinking (equivalent to "no")

    # Mouse behavior settings
    mouse_hide_wait = "-1"; # Never hide cursor (equivalent to hide-when-typing = "no")
    wheel_scroll_multiplier = "5.0"; # Enable smooth scrolling (similar to alternate-scroll-mode)

    # Background and foreground colors with transparency
    background_opacity = "0"; # 85% opaque, 15% transparent for nice transparency effect
    background = "#000000";
    foreground = "#ffffff";

    # Regular color palette (colors 0-7)
    color0 = "#000000"; # black
    color1 = "#ff0000"; # red
    color2 = "#00ff00"; # green
    color3 = "#ffff00"; # yellow
    color4 = "#1e90ff"; # blue
    color5 = "#ff00ff"; # magenta
    color6 = "#00ffff"; # cyan
    color7 = "#ffffff"; # white

    # Bright color palette (colors 8-15)
    color8 = "#808080"; # bright black
    color9 = "#ff0000"; # bright red
    color10 = "#00ff00"; # bright green
    color11 = "#ffff00"; # bright yellow
    color12 = "#1e90ff"; # bright blue
    color13 = "#ff00ff"; # bright magenta
    color14 = "#00ffff"; # bright cyan
    color15 = "#ffffff"; # bright white

    # Window settings
    window_padding_width = "0";
    confirm_os_window_close = "0";

    # Performance settings
    repaint_delay = "10";
    input_delay = "3";
    sync_to_monitor = "yes";
  };

  # Key bindings: assign shortcuts for clipboard copy and paste actions
  kittyKeyBindings = {
    "ctrl+c" = "copy_to_clipboard";
    "ctrl+v" = "paste_from_clipboard";
  };

  # Extra configuration for additional features
  kittyExtraConfig = ''
    # Audio and visual bell settings
    enable_audio_bell no
    visual_bell_duration 0.0
    window_alert_on_bell no
    bell_on_tab "🔔 "

    # Tab bar configuration
    tab_bar_edge bottom
    tab_bar_style powerline
    tab_powerline_style slanted

    # Window management
    remember_window_size yes
    initial_window_width 1280
    initial_window_height 720
  '';
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.ui.kitty = {
    enable = lib.mkEnableOption "kitty terminal emulator";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Programs
    ###########################################################################
    programs.kitty = {
      enable = true;

      # Font configuration
      font = {
        name = mainFontName;
        size = computedFontSize;
      };

      # Main settings
      settings = kittyMainSettings;

      # Key bindings
      keybindings = kittyKeyBindings;

      # Additional configuration
      extraConfig = kittyExtraConfig;

      # Shell integration
      shellIntegration = {
        enableZshIntegration = true;
        enableBashIntegration = true;
        enableFishIntegration = true;
      };
    };
  };
}

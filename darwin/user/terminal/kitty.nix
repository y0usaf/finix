{pkgs, ...}: {
  home-manager.users.y0usaf = {
    programs.kitty = {
      enable = true;

      settings = {
        # Font configuration
        font_family = "JetBrainsMono Nerd Font";
        font_size = 13;

        # Window
        window_padding_width = 8;
        hide_window_decorations = "titlebar-only";

        # Tab bar
        tab_bar_style = "powerline";
        tab_powerline_style = "slanted";

        # Performance
        repaint_delay = 10;
        input_delay = 3;
        sync_to_monitor = "yes";

        # Shell
        shell = "${pkgs.nushell}/bin/nu";

        # Cursor
        cursor_shape = "block";
        cursor_blink_interval = 0;

        # Colors (Catppuccin Mocha)
        background = "#1e1e2e";
        foreground = "#cdd6f4";
        selection_background = "#45475a";
        selection_foreground = "#cdd6f4";

        # Black
        color0 = "#45475a";
        color8 = "#585b70";

        # Red
        color1 = "#f38ba8";
        color9 = "#f38ba8";

        # Green
        color2 = "#a6e3a1";
        color10 = "#a6e3a1";

        # Yellow
        color3 = "#f9e2af";
        color11 = "#f9e2af";

        # Blue
        color4 = "#89b4fa";
        color12 = "#89b4fa";

        # Magenta
        color5 = "#f5c2e7";
        color13 = "#f5c2e7";

        # Cyan
        color6 = "#94e2d5";
        color14 = "#94e2d5";

        # White
        color7 = "#bac2de";
        color15 = "#a6adc8";

        # macOS specific
        macos_option_as_alt = "yes";
        macos_quit_when_last_window_closed = "yes";
        macos_show_window_title_in = "none";
      };
    };
  };
}

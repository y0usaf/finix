{
  config,
  lib,
  ...
}: {
  config.user.appearance.wallust = {
    targets = lib.optionalAttrs (lib.attrByPath ["user" "programs" "cmus" "enable"] false config) {
      "cmus-colors" = {
        template = "cmus-colors.theme";
        target = "~/.config/cmus/wallust-auto.theme";
      };
    };

    templates."cmus-colors.theme" = ''
      # Base colors
      set color_win_fg=default
      set color_win_bg=default
      set color_win_dir=default

      # Window styling - accent (color5/magenta)
      set color_win_cur=5
      set color_win_cur_sel_fg=15
      set color_win_cur_sel_bg=5
      set color_separator=darkgray

      # Command line
      set color_cmdline_bg=default
      set color_cmdline_fg=default

      # Status and title bars - accent color (color5/magenta)
      set color_statusline_fg=white
      set color_statusline_bg=5
      set color_statusline_progress_bg=5
      set color_statusline_progress_fg=white
      set color_win_title_fg=white
      set color_win_title_bg=5

      # Error messages
      set color_error=1
      set color_info=2
    '';
  };
}

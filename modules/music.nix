#===============================================================================
#                      🎵 Music Configuration 🎵
#===============================================================================
# 🎧 CMUS music player
# 📊 CAVA audio visualizer
# 🎨 Theme integration
#===============================================================================
{
  config,
  pkgs,
  lib,
  profile,
  ...
}: {
  config = lib.mkIf (builtins.elem "music" profile.features) {
    # Create CMUS configuration
    xdg.configFile."cmus/rc".text = ''
      # Set music directory
      cd ${profile.musicDir}

      # Color scheme
      set color_cmdline_bg=default
      set color_cmdline_fg=default
      set color_error=red
      set color_info=yellow
      set color_separator=blue
      set color_statusline_bg=default
      set color_statusline_fg=gray
      set color_titleline_bg=blue
      set color_titleline_fg=white
      set color_win_bg=default
      set color_win_cur=blue
      set color_win_cur_sel_bg=blue
      set color_win_cur_sel_fg=white
      set color_win_fg=default
      set color_win_sel_bg=blue
      set color_win_sel_fg=white
      set color_win_title_bg=blue
      set color_win_title_fg=white

      # Playback settings
      set continue=true
      set repeat=false
      set shuffle=off
      set softvol=true
      set vol_step=5

      # Display settings
      set show_hidden=false
      set show_current_bitrate=true
      set show_playback_position=true
      set show_remaining_time=true
      set status_display_program=${pkgs.cmus}/bin/cmus-status-display
    '';

    # Create CAVA configuration
    xdg.configFile."cava/config".text = ''
      [general]
      framerate = 240
      autosens = 1
      bars = 0
      bar_width = 1
      bar_spacing = 1

      [input]
      method = pulse
      source = auto

      [output]
      method = ncurses
      channels = stereo

      [color]
      gradient = 1
      gradient_color_1 = '#94e2d5'
      gradient_color_2 = '#89dceb'
      gradient_color_3 = '#74c7ec'
      gradient_color_4 = '#89b4fa'
      gradient_color_5 = '#cba6f7'
      gradient_color_6 = '#f5c2e7'
      gradient_color_7 = '#eba0ac'
      gradient_color_8 = '#f38ba8'

      [smoothing]
      integral = 77
      monstercat = 1
      waves = 0
      gravity = 100

      [eq]
      1 = 1
      2 = 1
      3 = 1
      4 = 1
      5 = 1
    '';

    # Create a systemd user service for auto-starting CAVA with the terminal
    systemd.user.services.cava = {
      Unit = {
        Description = "CAVA Audio Visualizer";
        After = ["graphical-session-pre.target"];
        PartOf = ["graphical-session.target"];
      };

      Service = {
        ExecStart = "${pkgs.cava}/bin/cava";
        Restart = "always";
        RestartSec = 3;
      };
    };
  };
}

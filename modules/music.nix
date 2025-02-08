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
      set color_cmdline_fg=226
      set color_error=226
      set color_info=226
      set color_separator=226
      set color_statusline_bg=default
      set color_statusline_fg=226
      set color_titleline_bg=226
      set color_titleline_fg=16
      set color_win_bg=default
      set color_win_cur=226
      set color_win_cur_sel_bg=226
      set color_win_cur_sel_fg=16
      set color_win_dir=226
      set color_win_fg=226
      set color_win_inactive_cur_sel_bg=default
      set color_win_inactive_cur_sel_fg=226
      set color_win_inactive_sel_bg=default
      set color_win_inactive_sel_fg=226
      set color_win_sel_bg=226
      set color_win_sel_fg=16
      set color_win_title_bg=226
      set color_win_title_fg=16

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
      bar_width = 2
      bar_spacing = 1

      [input]
      method = pulse
      source = auto

      [output]
      method = ncurses
      channels = stereo

      [color]
      gradient = 1
      gradient_color_1 = '#59cc33'
      gradient_color_2 = '#80cc33'
      gradient_color_3 = '#a6cc33'
      gradient_color_4 = '#cccc33'
      gradient_color_5 = '#cca633'
      gradient_color_6 = '#cc8033'
      gradient_color_7 = '#cc5933'
      gradient_color_8 = '#cc3333'

      [smoothing]
      noise_reduction = 77
      monstercat = 0
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

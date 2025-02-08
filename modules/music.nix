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
    # Placeholder

    # Create CAVA configuration
    programs.cava = {
      enable = true;
      settings = {
        general = {
          framerate = 240;
          autosens = 1;
          overshoot = 5;
          sensitivity = 50;
          bars = 100;
          bar_width = 2;
          bar_spacing = 1;
          lower_cutoff_freq = 50;
          higher_cutoff_freq = 10000;
          sleep_timer = 0;
        };

        input = {
          method = "pulse";
          source = "auto";
        };

        output = {
          method = "ncurses";
          orientation = "bottom";
          channels = "stereo";
          mono_option = "average";
          reverse = 0;
          alacritty_sync = 0;
        };

        color = {
          gradient = 0;
          gradient_count = 8;
          gradient_color_1 = "'#59cc33'";
          gradient_color_2 = "'#80cc33'";
          gradient_color_3 = "'#a6cc33'";
          gradient_color_4 = "'#cccc33'";
          gradient_color_5 = "'#cca633'";
          gradient_color_6 = "'#cc8033'";
          gradient_color_7 = "'#cc5933'";
          gradient_color_8 = "'#cc3333'";
        };

        smoothing = {
          noise_reduction = 90;
          monstercat = 0;
          waves = 0;
          gravity = 80;
        };

        eq = {
          "1" = 1;
          "2" = 1;
          "3" = 1;
          "4" = 1;
          "5" = 1;
        };
      };
    };
  };
}

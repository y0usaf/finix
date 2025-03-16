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
  config = {
    # Add music-related packages
    home.packages = with pkgs; [
      cmus # Command-line music player
      cava # Console-based audio visualizer
    ];

    # Create CMUS configuration
    # Placeholder

    # Create CAVA configuration with updated settings (gradient configuration removed)
    programs.cava = {
      enable = true;
      settings = {
        general = {
          autosens = 1;
          bar_spacing = 1;
          bar_width = 2;
          framerate = 300;
          higher_cutoff_freq = 20000;
          lower_cutoff_freq = 0;
          overshoot = 10;
          sensitivity = 25;
          sleep_timer = 0;
        };

        input = {
          method = "pulse";
          source = "auto";
        };

        output = {
          method = "ncurses";
          orientation = "bottom";
          channels = "mono";
        };

        smoothing = {
          noise_reduction = 95;
          monstercat = 0;
          waves = 0;
          gravity = 100;
        };

        eq = {
          "1" = 2;
          "2" = 1.5;
          "3" = 1;
          "4" = 1.5;
          "5" = 2;
        };
      };
    };
  };
}

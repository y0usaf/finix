###############################################################################
# Music Module
# Configuration for music players and audio visualization
# - CMUS command-line music player
# - CAVA console-based audio visualizer
# - Theme integration with system
###############################################################################
{
  config,
  pkgs,
  lib,
  profile,
  ...
}: let
  cfg = config.modules.programs.music;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.modules.programs.music = {
    enable = lib.mkEnableOption "music applications";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    home.packages = with pkgs; [
      cmus # Command-line music player
      cava # Console-based audio visualizer
    ];

    ###########################################################################
    # Programs
    ###########################################################################
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

    ###########################################################################
    # Configuration Files
    ###########################################################################
    # CMUS configuration placeholder - to be implemented
    # xdg.configFile = {
    #   "cmus/rc".text = ''
    #     # CMUS configuration
    #   '';
    # };
  };
}

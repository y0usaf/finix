###############################################################################
# Module Template
# Brief description of what this module does
# - Key feature 1
# - Key feature 2
# - Key feature 3
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.modules.example;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.modules.example = {
    enable = lib.mkEnableOption "example module";

    setting1 = lib.mkOption {
      type = lib.types.str;
      default = "default value";
      description = "Description of setting1";
    };

    setting2 = lib.mkOption {
      type = lib.types.int;
      default = 42;
      example = 100;
      description = "Description of setting2";
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Environment Variables
    ###########################################################################
    programs.zsh = {
      envExtra = ''
        # Module-specific environment variables
        export EXAMPLE_VAR="${cfg.setting1}"
      '';
    };

    ###########################################################################
    # Systemd Services
    ###########################################################################
    systemd.user.services = {
      example-service = {
        Unit = {
          Description = "Example Service";
          After = ["graphical-session.target"];
          PartOf = ["graphical-session.target"];
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.example}/bin/example";
          Restart = "on-failure";
          RestartSec = "5s";
        };
        Install = {
          WantedBy = ["graphical-session.target"];
        };
      };
    };

    ###########################################################################
    # Packages
    ###########################################################################
    home.packages = with pkgs; [
      # package1
      # package2
      # package3
    ];

    ###########################################################################
    # Programs
    ###########################################################################
    programs.example = {
      enable = true;
      # Additional program configuration
    };

    ###########################################################################
    # Desktop Entries
    ###########################################################################
    xdg.desktopEntries = {
      "example" = {
        name = "Example Application";
        exec = "example %U";
        terminal = false;
        categories = ["Category1" "Category2"];
        comment = "Example application";
        icon = "example-icon";
        mimeType = ["x-scheme-handler/example"];
      };
    };

    ###########################################################################
    # Configuration Files
    ###########################################################################
    xdg.configFile = {
      "example/config.json".text = ''
        {
          "setting1": "${cfg.setting1}",
          "setting2": ${toString cfg.setting2}
        }
      '';
    };
  };
}

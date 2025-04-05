###############################################################################
# Systemd Module
# Configures systemd user services and paths
# - Polkit authentication agent
# - Automatic Nix file formatting
# - Path watching for Nix configuration
###############################################################################
{
  config,
  pkgs,
  lib,
  profile,
  ...
}: let
  cfg = config.modules.core.systemd;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.modules.core.systemd = {
    enable = lib.mkEnableOption "systemd user services";

    autoFormatNix = {
      enable = lib.mkEnableOption "automatic Nix file formatting with alejandra";

      directory = lib.mkOption {
        type = lib.types.str;
        default = "${profile.homeDirectory}/nixos";
        description = "Directory to watch for Nix file changes";
      };
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    home.packages = lib.mkIf cfg.autoFormatNix.enable [
      pkgs.alejandra
    ];

    ###########################################################################
    # Systemd User Configuration
    ###########################################################################
    systemd.user = {
      # Global systemd user configuration
      startServices = "sd-switch";

      services = {
        polkit-gnome-authentication-agent-1 = {
          Unit = {
            Description = "polkit-gnome-authentication-agent-1";
            WantedBy = ["graphical-session.target"];
            After = ["graphical-session.target"];
          };
          Service = {
            Type = "simple";
            ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
            Restart = "on-failure";
            RestartSec = 1;
            TimeoutStopSec = 10;
          };
        };

        format-nix = lib.mkIf cfg.autoFormatNix.enable {
          Unit = {
            Description = "Format Nix files on change";
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${pkgs.alejandra}/bin/alejandra .";
            WorkingDirectory = cfg.autoFormatNix.directory;
          };
        };
      };

      paths.format-nix = lib.mkIf cfg.autoFormatNix.enable {
        Unit = {
          Description = "Watch NixOS config directory for changes";
        };
        Path = {
          PathModified = cfg.autoFormatNix.directory;
          Unit = "format-nix.service";
        };
        Install = {
          WantedBy = ["default.target"];
        };
      };
    };
  };
}

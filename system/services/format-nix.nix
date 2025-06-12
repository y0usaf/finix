###############################################################################
# Format Nix Service
# Automatic Nix file formatting with alejandra
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.services.formatNix;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.services.formatNix = {
    enable = lib.mkEnableOption "automatic Nix file formatting with alejandra";

    directory = lib.mkOption {
      type = lib.types.str;
      default = "${config.cfg.shared.homeDirectory}/nixos";
      description = "Directory to watch for Nix file changes";
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # System Packages
    ###########################################################################
    environment.systemPackages = with pkgs; [
      alejandra
    ];

    ###########################################################################
    # Systemd User Services
    ###########################################################################
    systemd.user.services.format-nix = {
      description = "Format Nix files on change";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.alejandra}/bin/alejandra .";
        WorkingDirectory = "%h/nixos";
      };
    };

    systemd.user.timers.format-nix = {
      description = "Timer for formatting Nix files";
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "5min";
        Unit = "format-nix.service";
      };
      wantedBy = ["timers.target"];
    };
  };
}

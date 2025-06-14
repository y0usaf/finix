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
  cfg = config.cfg.home.services.formatNix;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.home.services.formatNix = {
    enable = lib.mkEnableOption "automatic Nix file formatting with alejandra";

    directory = lib.mkOption {
      type = lib.types.str;
      default = "{{home}}/nixos";
      description = "Directory to watch for Nix file changes";
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Maid Configuration
    ###########################################################################
    users.users.y0usaf.maid = {
      packages = [pkgs.alejandra];
      
      systemd.services.format-nix = {
        description = "Format Nix files on change";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.alejandra}/bin/alejandra .";
          WorkingDirectory = "{{home}}/nixos";
        };
      };

      systemd.timers.format-nix = {
        description = "Timer for formatting Nix files";
        timerConfig = {
          OnBootSec = "1min";
          OnUnitActiveSec = "5min";
          Unit = "format-nix.service";
        };
        wantedBy = ["timers.target"];
      };
    };
  };
}

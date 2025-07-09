###############################################################################
# Syncthing Configuration (Maid Version)
# Simple syncthing service enablement
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.services.syncthing;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.services.syncthing = {
    enable = lib.mkEnableOption "Syncthing service";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Maid Configuration
    ###########################################################################
    users.users.y0usaf.maid = {
      packages = with pkgs; [
        syncthing
      ];

      ###########################################################################
      # Syncthing Configuration
      ###########################################################################
      file.xdg_config."syncthing/config.xml".text = ''
        <configuration version="37">
          <gui enabled="true" tls="false" debugging="false">
            <address>127.0.0.1:8384</address>
            <apikey></apikey>
            <theme>default</theme>
          </gui>
          <options>
            <startBrowser>false</startBrowser>
          </options>
        </configuration>
      '';
    };

    ###########################################################################
    # Enable system syncthing user service
    ###########################################################################
    systemd.user.services.syncthing = {
      enable = true;
      wantedBy = ["default.target"];
    };
  };
}

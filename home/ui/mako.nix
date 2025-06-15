###############################################################################
# Mako Notification Daemon (Maid Version)
# Wayland notification daemon with customizable appearance
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.cfg.home.ui.mako;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.home.ui.mako = {
    enable = lib.mkEnableOption "Mako notification daemon";
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
        mako
      ];

      ###########################################################################
      # Configuration Files
      ###########################################################################
      file.xdg_config."mako/config".text = ''
        actions=true
        anchor=top-right
        background-color=#2e3440
        border-color=#88c0d0
        border-radius=5
        border-size=1
        default-timeout=5000
        format=<b>%s</b>\n%b
        group-by=
        height=100
        icon-path=
        icons=true
        ignore-timeout=false
        layer=top
        margin=10
        markup=true
        max-icon-size=64
        max-visible=5
        output=
        padding=5
        progress-color=
        sort=-time
        text-color=#eceff4
        width=300
      '';

      ###########################################################################
      # User Systemd Service
      ###########################################################################
      systemd.services.mako = {
        description = "Mako notification daemon";
        documentation = ["man:mako(1)"];
        partOf = ["graphical-session.target"];
        after = ["graphical-session.target"];
        wantedBy = ["graphical-session.target"];
        serviceConfig = {
          Type = "dbus";
          BusName = "org.freedesktop.Notifications";
          ExecStart = "${pkgs.mako}/bin/mako";
          ExecReload = "${pkgs.mako}/bin/makoctl reload";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
      };
    };
  };
}

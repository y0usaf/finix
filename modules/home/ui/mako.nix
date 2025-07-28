{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.ui.mako;
in {
  options.home.ui.mako = {
    enable = lib.mkEnableOption "Mako notification daemon";
  };
  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name} = {
      packages = with pkgs; [
        mako
      ];
      files.".config/mako/config" = {
        clobber = true;
        text = ''
          actions=true
          anchor=top-right
          background-color=
          border-color=
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
          text-color=
          width=300
        '';
      };
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

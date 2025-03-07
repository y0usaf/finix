{
  config,
  pkgs,
  lib,
  profile,
  ...
}: {
  # User-level systemd configuration
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

      format-nix = {
        Unit = {
          Description = "Format Nix files on change";
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.alejandra}/bin/alejandra .";
          WorkingDirectory = "${profile.homeDirectory}/nixos";
        };
      };
    };

    paths.format-nix = {
      Unit = {
        Description = "Watch NixOS config directory for changes";
      };
      Path = {
        PathModified = "${profile.homeDirectory}/nixos";
        Unit = "format-nix.service";
      };
      Install = {
        WantedBy = ["default.target"];
      };
    };
  };
}

{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.services.syncthing;
in {
  options.home.services.syncthing = {
    enable = lib.mkEnableOption "Syncthing service";
  };
  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name} = {
      packages = with pkgs; [
        syncthing
      ];
      files.".config/syncthing/.keep" = {
        clobber = true;
        text = '''';
      };
    };
    systemd.user.services.syncthing = {
      enable = true;
      wantedBy = ["default.target"];
      after = ["network.target"];
      serviceConfig = {
        ExecStart = "${pkgs.syncthing}/bin/syncthing serve --no-browser --no-restart --logflags=0";
        Restart = "on-failure";
        RestartSec = "5s";
        WorkingDirectory = config.user.homeDirectory;
        StateDirectory = "syncthing";
        StateDirectoryMode = "0700";
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        ReadWritePaths = [config.user.homeDirectory];
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6"];
        SystemCallFilter = "@system-service";
        SystemCallErrorNumber = "EPERM";
      };
    };
  };
}

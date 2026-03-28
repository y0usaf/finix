{
  config,
  pkgs,
  lib,
  ...
}: let
  wallustLib = import ../../../../../lib/appearance/wallust {inherit lib;};
  wallustPkg = pkgs.wallust;
  inherit (config) user;
  userUi = user.ui;
  userPrograms = user.programs;
  vicinaeEnabled = userUi.vicinae.enable or false;
in {
  options.user.appearance.wallust = {
    defaultTheme = lib.mkOption {
      type = lib.types.str;
      default = "dopamine";
      description = "Default theme to apply on login. Can be a custom colorscheme name (dopamine, eva02, p4) or a built-in wallust theme (Synthwave, Tokyo-Night, etc.)";
    };
  };

  config = {
    environment.systemPackages = [
      wallustPkg
      # Wrapper script: runs wallust and updates pywalfox
      (pkgs.writeShellApplication {
        name = "wt";
        runtimeInputs = [wallustPkg pkgs.pywalfox-native];
        text = wallustLib.mkWtScriptText {
          browserBinary = "librewolf";
          inherit vicinaeEnabled;
        };
      })
    ];

    # Systemd user service to apply default theme on login
    systemd.user.services.wallust-default = {
      description = "Apply default wallust theme";
      wantedBy = ["graphical-session-pre.target"];
      before = [
        "graphical-session.target"
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "wallust-default" (wallustLib.mkStartupScript {
          wallustBin = "${wallustPkg}/bin/wallust";
          inherit (user.appearance.wallust) defaultTheme;
        });
        RemainAfterExit = true;
      };
    };

    # Config files via bayt
    bayt.users."${config.user.name}".files = lib.mapAttrs (_: content: {text = content;}) (wallustLib.mkFiles {
      zjstatusEnabled = user.shell.zellij.zjstatus.enable;
      niriEnabled = userUi.niri.enable or false;
      inherit vicinaeEnabled;
      cmusEnabled = userPrograms.cmus.enable or false;
      vestopkEnabled = userPrograms.discord.vesktop.enable or false;
      gpuishellEnabled = userUi.gpuishell.enable or false;
    });
  };
}

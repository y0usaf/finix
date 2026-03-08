{
  config,
  pkgs,
  lib,
  ...
}: let
  wallustLib = import ../../../../../lib/appearance/wallust {inherit lib;};
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
      pkgs.wallust
      # Wrapper script: runs wallust and updates pywalfox
      (pkgs.writeShellApplication {
        name = "wt";
        runtimeInputs = [pkgs.wallust pkgs.pywalfox-native];
        text = wallustLib.mkWtScriptText {
          browserBinary = "librewolf";
          vicinaeEnabled = config.user.ui.vicinae.enable or false;
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
          wallustBin = "${pkgs.wallust}/bin/wallust";
          inherit (config.user.appearance.wallust) defaultTheme;
        });
        RemainAfterExit = true;
      };
    };

    # Config files via hjem
    usr.files = lib.mapAttrs (_: content: {text = content;}) (wallustLib.mkFiles {
      zjstatusEnabled = config.user.shell.zellij.zjstatus.enable;
      niriEnabled = config.user.ui.niri.enable or false;
      vicinaeEnabled = config.user.ui.vicinae.enable or false;
      cmusEnabled = config.user.programs.cmus.enable or false;
      vestopkEnabled = config.user.programs.discord.vesktop.enable or false;
      gpuishellEnabled = config.user.ui.gpuishell.enable or false;
    });
  };
}

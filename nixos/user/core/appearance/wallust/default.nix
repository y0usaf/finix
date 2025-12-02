{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.user.appearance.wallust;
  discordCfg = config.user.programs.discord;
  wallustLib = import ../../../../../lib/appearance/wallust {inherit lib;};
  files = wallustLib.mkFiles {
    zjstatusEnabled = config.user.shell.zellij.zjstatus.enable;
    discordStable = discordCfg.stable.enable or false;
    discordVesktop = discordCfg.vesktop.enable or false;
    discordMinimalImprovement = discordCfg.vesktop.enable or discordCfg.stable.enable or false;
    niriEnabled = config.user.ui.niri.enable or false;
    agsEnabled = config.user.ui.ags.enable or false;
  };
in {
  options.user.appearance.wallust = {
    defaultTheme = lib.mkOption {
      type = lib.types.str;
      default = "dopamine";
      description = "Default theme to apply on login. Can be a custom colorscheme name (dopamine, sunset-red, golden) or a built-in wallust theme (Synthwave, Tokyo-Night, etc.)";
    };
  };

  config = {
    environment.systemPackages = [
      pkgs.wallust
      # Wrapper script: runs wallust and updates pywalfox
      (pkgs.writeShellApplication {
        name = "wt";
        runtimeInputs = [pkgs.wallust pkgs.pywalfox-native];
        text = wallustLib.mkWtScriptText {browserBinary = "librewolf";};
      })
    ];

    # Systemd user service to apply default theme on login
    systemd.user.services.wallust-default = {
      description = "Apply default wallust theme";
      wantedBy = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "wallust-default" (wallustLib.mkStartupScript {
          wallustBin = "${pkgs.wallust}/bin/wallust";
          inherit (cfg) defaultTheme;
        });
        RemainAfterExit = true;
      };
    };

    # Config files via hjem
    hjem.users.${config.user.name}.files = lib.mapAttrs (_: content: {text = content;}) files;
  };
}

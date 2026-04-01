{
  config,
  pkgs,
  lib,
  ...
}: let
  wallustLib = import ./data/wallust-lib.nix {inherit lib;};
  wallustPkg = pkgs.wallust;
  wallustCfg = config.user.appearance.wallust;
  zjstatusEnabled = lib.attrByPath ["user" "shell" "zellij" "zjstatus" "enable"] false config;
  niriEnabled = lib.attrByPath ["user" "ui" "niri" "enable"] false config;
  vicinaeEnabled = lib.attrByPath ["user" "ui" "vicinae" "enable"] false config;
  cmusEnabled = lib.attrByPath ["user" "programs" "cmus" "enable"] false config;
  vesktopEnabled = lib.attrByPath ["user" "programs" "discord" "vesktop" "enable"] false config;
  gpuishellEnabled = lib.attrByPath ["user" "ui" "gpuishell" "enable"] false config;
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
          inherit (wallustCfg) defaultTheme;
        });
        RemainAfterExit = true;
      };
    };

    # Config files via bayt
    bayt.users."${config.user.name}".files = lib.mapAttrs (_: content: {text = content;}) (wallustLib.mkFiles {
      inherit
        zjstatusEnabled
        niriEnabled
        vicinaeEnabled
        cmusEnabled
        gpuishellEnabled
        ;
      vestopkEnabled = vesktopEnabled;
    });
  };
}

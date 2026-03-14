{
  config,
  pkgs,
  lib,
  ...
}: let
  wallustLib = import ../../../../lib/appearance/wallust {inherit lib;};
  wallustPkg = pkgs.wallust;
  inherit (config) user;
  wallustCfg = user.appearance.wallust;
in {
  options.user.appearance.wallust = {
    enable = lib.mkEnableOption "wallust dynamic theming";

    defaultTheme = lib.mkOption {
      type = lib.types.str;
      default = "dopamine";
      description = "Default theme to apply. Can be a custom colorscheme name (dopamine, eva02, p4) or a built-in wallust theme (Synthwave, Tokyo-Night, etc.)";
    };
  };

  config = lib.mkIf wallustCfg.enable {
    environment.systemPackages = [
      wallustPkg
      # Wrapper script: runs wallust and updates pywalfox
      (pkgs.writeShellApplication {
        name = "wt";
        runtimeInputs = [wallustPkg pkgs.pywalfox-native];
        text = wallustLib.mkWtScriptText {browserBinary = "librewolf";};
      })
    ];

    home-manager.users."${user.name}" = {
      # Config files via home-manager
      home.file = lib.mapAttrs (_: content: {text = content;}) (wallustLib.mkFiles {
        zjstatusEnabled = user.shell.zellij.zjstatus.enable;
      });

      # launchd agent to apply theme on login
      launchd.agents.wallust-default = {
        enable = true;
        config = {
          Label = "com.wallust.default-theme";
          ProgramArguments = [
            "${pkgs.bash}/bin/bash"
            "-c"
            (wallustLib.mkStartupScript {
              wallustBin = "${wallustPkg}/bin/wallust";
              inherit (wallustCfg) defaultTheme;
            })
          ];
          RunAtLoad = true;
        };
      };
    };
  };
}

{
  config,
  pkgs,
  lib,
  ...
}: let
  wallustLib = import ../../../../lib/appearance/wallust {inherit lib;};
in {
  options.user.appearance.wallust = {
    enable = lib.mkEnableOption "wallust dynamic theming";

    defaultTheme = lib.mkOption {
      type = lib.types.str;
      default = "dopamine";
      description = "Default theme to apply. Can be a custom colorscheme name (dopamine, eva02, p4) or a built-in wallust theme (Synthwave, Tokyo-Night, etc.)";
    };
  };

  config = lib.mkIf config.user.appearance.wallust.enable {
    environment.systemPackages = [
      pkgs.wallust
      # Wrapper script: runs wallust and updates pywalfox
      (pkgs.writeShellApplication {
        name = "wt";
        runtimeInputs = [pkgs.wallust pkgs.pywalfox-native];
        text = wallustLib.mkWtScriptText {browserBinary = "librewolf";};
      })
    ];

    home-manager.users.${config.user.name} = {
      # Config files via home-manager
      home.file = lib.mapAttrs (_: content: {text = content;}) (wallustLib.mkFiles {
        zjstatusEnabled = config.user.shell.zellij.zjstatus.enable;
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
              wallustBin = "${pkgs.wallust}/bin/wallust";
              inherit (config.user.appearance.wallust) defaultTheme;
            })
          ];
          RunAtLoad = true;
        };
      };
    };
  };
}

{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.user.appearance.wallust;
  wallustLib = import ../../../../lib/appearance/wallust {inherit lib;};
  files = wallustLib.mkFiles {zjstatusEnabled = config.user.shell.zellij.zjstatus.enable;};
in {
  options.user.appearance.wallust = {
    enable = lib.mkEnableOption "wallust dynamic theming";

    defaultTheme = lib.mkOption {
      type = lib.types.str;
      default = "dopamine";
      description = "Default theme to apply. Can be a custom colorscheme name (dopamine, sunset-red, golden) or a built-in wallust theme (Synthwave, Tokyo-Night, etc.)";
    };
  };

  config = lib.mkIf cfg.enable {
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
      home.file = lib.mapAttrs (_: content: {text = content;}) files;

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
              inherit (cfg) defaultTheme;
            })
          ];
          RunAtLoad = true;
        };
      };
    };
  };
}

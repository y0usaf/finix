{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.example;
in {
  options.example = {
    enable = lib.mkEnableOption "example module";
    setting1 = lib.mkOption {
      type = lib.types.str;
      default = "default value";
      description = "Description of setting1";
    };
    setting2 = lib.mkOption {
      type = lib.types.int;
      default = 42;
      example = 100;
      description = "Description of setting2";
    };
  };
  config = lib.mkIf cfg.enable {
    programs.zsh = {
      envExtra = ''
        export EXAMPLE_VAR="${cfg.setting1}"
      '';
    };
    systemd.user.services = {
      example-service = {
        Unit = {
          Description = "Example Service";
          After = ["graphical-session.target"];
          PartOf = ["graphical-session.target"];
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.example}/bin/example";
          Restart = "on-failure";
          RestartSec = "5s";
        };
        Install = {
          WantedBy = ["graphical-session.target"];
        };
      };
    };
    home.packages = with pkgs; [
    ];
    programs.example = {
      enable = true;
    };
    xdg.desktopEntries = {
      "example" = {
        name = "Example Application";
        exec = "example %U";
        terminal = false;
        categories = ["Category1" "Category2"];
        comment = "Example application";
        icon = "example-icon";
        mimeType = ["x-scheme-handler/example"];
      };
    };
    xdg.configFile = {
      "example/config.json".text = ''
        {
          "setting1": "${cfg.setting1}",
          "setting2": ${toString cfg.setting2}
        }
      '';
    };
  };
}

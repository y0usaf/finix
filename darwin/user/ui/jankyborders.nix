{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.user.ui.jankyborders;
in {
  options.user.ui.jankyborders = {
    enable = mkEnableOption "jankyborders window borders";

    style = mkOption {
      type = types.enum ["round" "square"];
      default = "square";
    };

    width = mkOption {
      type = types.float;
      default = 2.0;
    };

    activeColor = mkOption {
      type = types.str;
      default = "0xffffffff";
    };

    inactiveColor = mkOption {
      type = types.str;
      default = "0xff333333";
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.y0usaf = {
      home.file.".config/borders/bordersrc" = {
        executable = true;
        text = ''
          #!/bin/bash

          options=(
              style=${cfg.style}
              width=${toString cfg.width}
              hidpi=off
              active_color=${cfg.activeColor}
              inactive_color=${cfg.inactiveColor}
          )

          borders "''${options[@]}"
        '';
      };
    };
  };
}

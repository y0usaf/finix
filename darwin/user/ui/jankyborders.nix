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
      description = "Border style";
    };

    width = mkOption {
      type = types.float;
      default = 2.0;
      description = "Border width in points";
    };

    activeColor = mkOption {
      type = types.str;
      default = "0xffffffff";
      description = "Active window border color (ARGB format)";
    };

    inactiveColor = mkOption {
      type = types.str;
      default = "0xff333333";
      description = "Inactive window border color (ARGB format)";
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

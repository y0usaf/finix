{
  config,
  lib,
  ...
}: {
  options.user.ui.jankyborders = {
    enable = lib.mkEnableOption "jankyborders window borders";

    style = lib.mkOption {
      type = lib.types.enum ["round" "square"];
      default = "square";
    };

    width = lib.mkOption {
      type = lib.types.float;
      default = 2.0;
    };

    activeColor = lib.mkOption {
      type = lib.types.str;
      default = "0xffffffff";
    };

    inactiveColor = lib.mkOption {
      type = lib.types.str;
      default = "0xff333333";
    };
  };

  config = lib.mkIf config.user.ui.jankyborders.enable {
    home-manager.users."${config.user.name}" = {
      home.file.".config/borders/bordersrc" = {
        executable = true;
        text = ''
          #!/bin/bash

          options=(
              style=${config.user.ui.jankyborders.style}
              width=${toString config.user.ui.jankyborders.width}
              hidpi=off
              active_color=${config.user.ui.jankyborders.activeColor}
              inactive_color=${config.user.ui.jankyborders.inactiveColor}
          )

          borders "''${options[@]}"
        '';
      };
    };
  };
}

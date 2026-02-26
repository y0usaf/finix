{
  config,
  lib,
  ...
}:
with lib; {
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

  config = mkIf config.user.ui.jankyborders.enable {
    home-manager.users.${config.user.name} = {
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

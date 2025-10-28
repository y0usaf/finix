{
  pkgs,
  iosevkaSlab,
  ...
}: {
  home-manager.users.y0usaf = {
    # Install Fast Iosevka Slab font
    home.packages = [
      iosevkaSlab
    ];

    # Copy font to ~/Library/Fonts so macOS can find them
    home.activation.copyFastFonts = pkgs.lib.mkAfter ''
      run mkdir -p $HOME/Library/Fonts
      run cp -f ${iosevkaSlab}/share/fonts/truetype/* $HOME/Library/Fonts/ || true
    '';

    programs.alacritty = {
      enable = true;

      settings = {
        env = {
          TERM = "xterm-256color";
        };

        terminal = {
          shell = {
            program = "${pkgs.nushell}/bin/nu";
            args = ["-l"];
          };
        };

        font = {
          normal = {
            family = "Iosevka Term Slab";
            style = "Regular";
          };
          size = 13;
        };

        window = {
          padding = {
            x = 8;
            y = 8;
          };
          opacity = 0.5;
          decorations = "none";
        };

        cursor = {
          style = {
            shape = "Beam";
            blinking = "Off";
          };
        };

        mouse = {
          hide_when_typing = false;
        };

        colors = {
          primary = {
            background = "#000000";
            foreground = "#ffffff";
          };

          normal = {
            black = "#000000";
            red = "#ff0000";
            green = "#00ff00";
            yellow = "#ffff00";
            blue = "#1e90ff";
            magenta = "#ff00ff";
            cyan = "#00ffff";
            white = "#ffffff";
          };

          bright = {
            black = "#808080";
            red = "#ff0000";
            green = "#00ff00";
            yellow = "#ffff00";
            blue = "#1e90ff";
            magenta = "#ff00ff";
            cyan = "#00ffff";
            white = "#ffffff";
          };
        };
      };
    };
  };
}

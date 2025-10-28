{
  config,
  lib,
  pkgs,
  iosevkaSlab,
  ...
}: {
  options.user.ui.fonts = {
    enable = lib.mkEnableOption "font configuration and management";
  };

  config = lib.mkIf config.user.ui.fonts.enable {
    home-manager.users.y0usaf = {
      # Install fontconfig and the main font
      home.packages = [
        pkgs.fontconfig
        iosevkaSlab
      ];

      # Copy font to ~/Library/Fonts
      home.activation.copyFastFonts = pkgs.lib.mkAfter ''
        run mkdir -p $HOME/Library/Fonts
        run cp -f ${iosevkaSlab}/share/fonts/truetype/* $HOME/Library/Fonts/ || true
      '';

      # Configure fontconfig to set Iosevka Term Slab as monospace default
      xdg.configFile."fontconfig/fonts.conf" = {
        text = ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
          <fontconfig>
            <!-- Set monospace font default -->
            <alias>
              <family>monospace</family>
              <prefer>
                <family>Iosevka Term Slab</family>
              </prefer>
            </alias>

            <!-- Font rendering options -->
            <match target="font">
              <edit name="antialias" mode="assign"><bool>true</bool></edit>
              <edit name="hinting" mode="assign"><bool>true</bool></edit>
              <edit name="hintstyle" mode="assign"><const>hintslight</const></edit>
              <edit name="rgba" mode="assign"><const>rgb</const></edit>
              <edit name="autohint" mode="assign"><bool>true</bool></edit>
              <edit name="lcdfilter" mode="assign"><const>lcdlight</const></edit>
            </match>
          </fontconfig>
        '';
      };
    };
  };
}

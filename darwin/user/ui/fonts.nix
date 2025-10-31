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
      home.packages = [
        pkgs.fontconfig
        iosevkaSlab
      ];

      home.activation.copyFastFonts = pkgs.lib.mkAfter ''
        run mkdir -p $HOME/Library/Fonts
        run cp -f ${iosevkaSlab}/share/fonts/truetype/* $HOME/Library/Fonts/ || true
      '';

      xdg.configFile."fontconfig/fonts.conf" = {
        text = ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
          <fontconfig>
            <alias>
              <family>monospace</family>
              <prefer>
                <family>Iosevka Term Slab</family>
              </prefer>
            </alias>

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

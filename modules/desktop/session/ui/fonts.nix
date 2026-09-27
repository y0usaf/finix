{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: {
  options.user.ui.fonts = {
    mainFontName = lib.mkOption {
      type = lib.types.str;
      default = "Departure Mono Ultra Condensed";
      description = "Main font family name";
    };
    backup.name = lib.mkOption {
      type = lib.types.str;
      default = "Noto Sans CJK";
      description = "Backup font family name";
    };
    emoji.name = lib.mkOption {
      type = lib.types.str;
      default = "Noto Color Emoji";
      description = "Emoji font family name";
    };
  };

  config = {
    fonts.packages = [
      flakeInputs.fonts.packages."${pkgs.stdenv.hostPlatform.system}".default
      pkgs.noto-fonts-cjk-sans
      pkgs.noto-fonts-color-emoji
      pkgs.nerd-fonts.symbols-only
    ];

    manzil.users."${config.user.name}" = {
      files.".config/fontconfig/fonts.conf" = {
        text = ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
          <fontconfig>
            <!-- Disable all fonts by default -->
            <selectfont>
              <rejectfont>
                <pattern>
                  <patelt name="family">
                    <string>*</string>
                  </patelt>
                </pattern>
              </rejectfont>
            </selectfont>
            <!-- Explicitly enable only main, emoji, and CJK fonts -->
            <selectfont>
              <acceptfont>
                <pattern>
                  <patelt name="family">
                    <string>${config.user.ui.fonts.mainFontName}</string>
                  </patelt>
                </pattern>
                <pattern>
                  <patelt name="family">
                    <string>${config.user.ui.fonts.backup.name}</string>
                  </patelt>
                </pattern>
                <pattern>
                  <patelt name="family">
                    <string>Symbols Nerd Font</string>
                  </patelt>
                </pattern>
                <pattern>
                  <patelt name="family">
                    <string>${config.user.ui.fonts.emoji.name}</string>
                  </patelt>
                </pattern>
              </acceptfont>
            </selectfont>
            <!-- Set main font as default -->
            <match>
              <test name="family">
                <string>*</string>
              </test>
              <edit name="family" mode="prepend">
                <string>${config.user.ui.fonts.mainFontName}</string>
              </edit>
            </match>
            <!-- Fallback font configuration -->
            <alias binding="strong">
              <family>monospace</family>
              <prefer>
                <family>${config.user.ui.fonts.mainFontName}</family>
                <family>${config.user.ui.fonts.backup.name}</family>
                <family>Symbols Nerd Font</family>
                <family>${config.user.ui.fonts.emoji.name}</family>
              </prefer>
            </alias>
            <alias binding="strong">
              <family>sans-serif</family>
              <prefer>
                <family>${config.user.ui.fonts.mainFontName}</family>
                <family>${config.user.ui.fonts.backup.name}</family>
                <family>Symbols Nerd Font</family>
                <family>${config.user.ui.fonts.emoji.name}</family>
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
              <edit name="dpi" mode="assign"><double>${toString config.user.appearance.dpi}</double></edit>
            </match>
          </fontconfig>
        '';
      };
    };
  };
}

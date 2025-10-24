{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.ui.fonts = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable font configuration with monospace, emoji, and CJK fonts";
    };
    mainFont = lib.mkOption {
      type = lib.types.package;
      description = "Main monospace font package";
    };
    mainFontName = lib.mkOption {
      type = lib.types.str;
      description = "Main font family name";
    };
    emoji = lib.mkOption {
      type = lib.types.submodule {
        options = {
          package = lib.mkOption {
            type = lib.types.package;
            default = pkgs.noto-fonts-emoji;
            description = "Emoji font package";
          };
          name = lib.mkOption {
            type = lib.types.str;
            default = "Noto Color Emoji";
            description = "Emoji font family name";
          };
        };
      };
      default = {};
      description = "Emoji font configuration";
    };
    cjk = lib.mkOption {
      type = lib.types.submodule {
        options = {
          package = lib.mkOption {
            type = lib.types.package;
            default = pkgs.noto-fonts-cjk-sans;
            description = "CJK font package";
          };
          name = lib.mkOption {
            type = lib.types.str;
            default = "Noto Sans CJK";
            description = "CJK font family name";
          };
        };
      };
      default = {};
      description = "CJK font configuration";
    };
  };

  config = lib.mkIf config.user.ui.fonts.enable {
    fonts.packages = [
      config.user.ui.fonts.mainFont
      config.user.ui.fonts.emoji.package
      config.user.ui.fonts.cjk.package
    ];

    hjem.users.${config.user.name} = {
      files.".config/fontconfig/fonts.conf" = {
        clobber = true;
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
                    <string>${config.user.ui.fonts.emoji.name}</string>
                  </patelt>
                </pattern>
                <pattern>
                  <patelt name="family">
                    <string>${config.user.ui.fonts.cjk.name}</string>
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
            <alias>
              <family>monospace</family>
              <prefer>
                <family>${config.user.ui.fonts.mainFontName}</family>
                <family>${config.user.ui.fonts.cjk.name}</family>
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

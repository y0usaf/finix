{
  config,
  lib,
  ...
}: let
  cfg = config.home.ui.fonts;
  username = config.user.name;
  mainFontPackages = map (x: x.package) config.home.core.appearance.fonts.main;
  mainFontNames = map (x: x.name) config.home.core.appearance.fonts.main;
  fallbackPackages = map (x: x.package) config.home.core.appearance.fonts.fallback;
  fallbackNames = map (x: x.name) config.home.core.appearance.fonts.fallback;
  fontXmlConfig = ''
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
      <!-- Explicitly enable only our chosen fonts -->
      <selectfont>
        <acceptfont>
          <pattern>
            <patelt name="family">
              <string>${builtins.elemAt mainFontNames 0}</string>
            </patelt>
          </pattern>
          ${lib.concatMapStrings (name: ''
        <pattern>
          <patelt name="family">
            <string>${name}</string>
          </patelt>
        </pattern>
      '')
      fallbackNames}
        </acceptfont>
      </selectfont>
      <!-- Set main font as default -->
      <match>
        <test name="family">
          <string>*</string>
        </test>
        <edit name="family" mode="prepend">
          <string>${builtins.elemAt mainFontNames 0}</string>
        </edit>
      </match>
      <!-- Fallback font configuration -->
      <alias>
        <family>monospace</family>
        <prefer>
          <family>${builtins.elemAt mainFontNames 0}</family>
          ${lib.concatMapStrings (name: "<family>${name}</family>") fallbackNames}
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
        <edit name="dpi" mode="assign"><double>${toString config.home.core.appearance.dpi}</double></edit>
      </match>
    </fontconfig>
  '';
in {
  options.home.ui.fonts = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable font configuration with string substitution";
    };
  };
  config = lib.mkIf cfg.enable {
    users.users.${username}.maid = {
      packages = mainFontPackages ++ fallbackPackages;
      file.xdg_config = {
        "fontconfig/fonts.conf".text = fontXmlConfig;
      };
    };
  };
}

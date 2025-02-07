#─────────────────────── 🔤 FONT CONFIGURATION ───────────────────────#
# ⚠️  Affects system-wide font rendering and availability            #
#──────────────────────────────────────────────────────────────────────#
{
  config,
  pkgs,
  lib,
  profile,
  ...
}: let
  # Get the packages and names from the profile
  mainFontPackages = map (x: builtins.elemAt x 0) profile.fonts.main;
  mainFontNames = map (x: builtins.elemAt x 1) profile.fonts.main;
  fallbackPackages = map (x: builtins.elemAt x 0) profile.fonts.fallback;
  fallbackNames = map (x: builtins.elemAt x 1) profile.fonts.fallback;

  #######################################################################
  # Font XML Configuration String
  #
  # This string sets up the fontconfig rules:
  #  • Prioritizes the main font for all text.
  #  • Defines fallback fonts for symbols and extended Unicode support.
  #  • Configures font rendering options such as antialiasing, hinting,
  #    subpixel rendering, and DPI settings.
  #######################################################################
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
          '') fallbackNames}
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
        <edit name="dpi" mode="assign"><double>${toString profile.dpi}</double></edit>
      </match>
    </fontconfig>
  '';
in {
  #######################################################################
  # System-wide Font Configuration
  #######################################################################

  # Enable fontconfig management in the system and disable Home Manager's.
  fonts.fontconfig.enable = true;

  #######################################################################
  # Fontconfig File: Provide the generated XML configuration
  #######################################################################
  xdg.configFile."fontconfig/fonts.conf".text = fontXmlConfig;

  #######################################################################
  # Font Package Installation
  #
  # Installs the main font and all fallback fonts specified in the profile.
  #######################################################################
  home.packages = mainFontPackages ++ fallbackPackages;
}

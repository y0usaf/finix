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
  #######################################################################
  # Helper Function: Retrieve a package from its attribute path
  #######################################################################
  getPackage = path: lib.getAttrFromPath path pkgs;

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
      <!-- Main Font: Prioritize the primary font for all text -->
      <match>
        <test name="family">
          <string>*</string>
        </test>
        <edit name="family" mode="prepend">
          <string>${profile.mainFont.name}</string>
        </edit>
      </match>

      <!-- Fallback Fonts: Define aliases for fallback font families -->
      <alias>
        <family>monospace</family>
        <prefer>
          <family>${profile.mainFont.name}</family>
          ${lib.concatMapStrings (font: "\n                        <family>${font.name}</family>") profile.fallbackFonts}
        </prefer>
      </alias>

      <!-- Font Rendering Options: Enable smoothing and subpixel rendering -->
      <match target="font">
        <edit name="antialias" mode="assign">
          <bool>true</bool>
        </edit>
        <edit name="hinting" mode="assign">
          <bool>true</bool>
        </edit>
        <edit name="hintstyle" mode="assign">
          <const>hintslight</const>
        </edit>
        <edit name="rgba" mode="assign">
          <const>rgb</const>
        </edit>
        <edit name="autohint" mode="assign">
          <bool>true</bool>
        </edit>
        <edit name="lcdfilter" mode="assign">
          <const>lcdlight</const>
        </edit>
        <edit name="dpi" mode="assign">
          <double>${toString profile.dpi}</double>
        </edit>
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
  home.packages = 
    (map (pkgPath: getPackage pkgPath) profile.mainFont.package)
    ++ lib.flatten (map (font: map (pkgPath: getPackage pkgPath) font.package) profile.fallbackFonts);
}

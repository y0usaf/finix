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
  # Helper function to get package from attribute path
  getPackage = path: lib.getAttrFromPath path pkgs;
in {
  # Disable Home Manager's font management
  fonts.fontconfig.enable = false;

  #── 📝 Font Configuration ──────────────────#
  xdg.configFile."fontconfig/fonts.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
            <!-- Prioritize main font for all text -->
            <match>
                    <test name="family">
                            <string>*</string>
                    </test>
                    <edit name="family" mode="prepend">
                            <string>${profile.mainFont.name}</string>
                    </edit>
            </match>

            <!-- Fallback fonts for symbols and wide Unicode support -->
            <alias>
                    <family>monospace</family>
                    <prefer>
                            <family>${profile.mainFont.name}</family>
                            ${lib.concatMapStrings (font: ''
        <family>${font.name}</family>
      '')
      profile.fallbackFonts}
                    </prefer>
            </alias>

            <!-- Enable font smoothing and set font rendering options -->
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

  #── 📦 Font Packages ────────────────────────#
  home.packages =
    [
      # Install main font
      (getPackage profile.mainFont.package)
    ]
    ++
    # Install all fallback fonts
    (map (font: getPackage font.package) profile.fallbackFonts);
}

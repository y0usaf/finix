{
  config,
  pkgs,
  lib,
  globals,
  ...
}: {
  xdg.configFile."fontconfig/fonts.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
        <!-- Prioritize IosevkaTermSlab for all text -->
        <match>
            <test name="family">
                <string>*</string>
            </test>
            <edit name="family" mode="prepend">
                <string>IosevkaTermSlab Nerd Font Mono</string>
            </edit>
        </match>

        <!-- Fallback fonts for symbols and wide Unicode support -->
        <alias>
            <family>monospace</family>
            <prefer>
                <family>IosevkaTermSlab Nerd Font Mono</family>
                <family>Symbols Nerd Font Mono</family>
                <family>Noto Color Emoji</family>
                <family>Noto Sans Symbols</family>
                <family>Noto Sans Symbols 2</family>
                <family>DejaVu Sans Mono</family>
                <family>Font Awesome</family>
                <family>Noto Sans CJK</family>
                <family>Noto Sans</family>
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
                <double>109</double>
            </edit>
        </match>
    </fontconfig>
  '';

  # Ensure required fonts are installed
  home.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    noto-fonts-extra
    font-awesome
    dejavu_fonts
    nerd-fonts.iosevka-term-slab
  ];
}

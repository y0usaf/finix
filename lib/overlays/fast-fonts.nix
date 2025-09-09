sources: final: _prev: {
  fastFonts = final.stdenvNoCC.mkDerivation {
    pname = "fast-fonts";
    version = "1.0.0";
    src = sources.Fast-Fonts + "/fonts";

    installPhase = ''
      mkdir -p $out/share/fonts/truetype
      find . -name "*.ttf" -exec install -m444 {} $out/share/fonts/truetype/ \;
    '';

    meta = with final.lib; {
      description = "Custom fast reading fonts by y0usaf";
      homepage = "https://github.com/y0usaf/Fast-Fonts";
      platforms = platforms.all;
      license = licenses.mit;
    };
  };
}

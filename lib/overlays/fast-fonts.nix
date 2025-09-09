sources: _final: prev: {
  fastFonts = prev.stdenvNoCC.mkDerivation {
    pname = "fast-fonts";
    version = "1.0.0";
    src = sources.Fast-Fonts + "/fonts";

    installPhase = ''
      mkdir -p $out/share/fonts/truetype
      find . -name "*.ttf" -exec install -m444 {} $out/share/fonts/truetype/ \;
    '';

    meta = with prev.lib; {
      description = "Fast reading fonts by y0usaf";
      homepage = "https://github.com/y0usaf/Fast-Fonts";
      platforms = platforms.all;
      license = licenses.mit;
    };
  };
}

sources:
# Fast fonts overlay
final: _prev: {
  fastFonts = final.stdenvNoCC.mkDerivation {
    pname = "fast-fonts";
    version = "1.0.0";
    src = sources.Fast-Font;

    installPhase = ''
      mkdir -p $out/share/fonts/truetype
      install -m444 -Dt $out/share/fonts/truetype *.ttf
      mkdir -p $out/share/doc/fast-fonts
      if [ -f LICENSE ]; then
        install -m444 -Dt $out/share/doc/fast-fonts LICENSE
      fi
      if [ -f README.md ]; then
        install -m444 -Dt $out/share/doc/fast-fonts README.md
      fi
    '';

    meta = with final.lib; {
      description = "Fast Font Collection - TTF fonts";
      longDescription = "Fast Font Collection provides optimized monospace and sans-serif fonts";
      homepage = "https://github.com/y0usaf/Fast-Font";
      platforms = platforms.all;
      license = licenses.mit;
    };
  };
}

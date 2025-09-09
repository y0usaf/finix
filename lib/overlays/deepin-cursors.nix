sources: final: prev: {
  deepin-dark-hyprcursor = prev.stdenv.mkDerivation {
    name = "deepin-dark-hyprcursor";
    src = sources.Deepin-Dark-hyprcursor;
    installPhase = ''
      mkdir -p $out/share/icons
      cp -r * $out/share/icons/
    '';
  };

  deepin-dark-xcursor = prev.stdenv.mkDerivation {
    name = "deepin-dark-xcursor";
    src = sources.Deepin-Dark-xcursor;
    installPhase = ''
      mkdir -p $out/share/icons
      cp -r * $out/share/icons/
    '';
  };
}

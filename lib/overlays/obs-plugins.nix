sources: _final: prev: {
  obs-studio-plugins =
    prev.obs-studio-plugins
    // {
      obs-backgroundremoval = prev.obs-studio-plugins.obs-backgroundremoval.overrideAttrs (_: {
        src = sources.obs-backgroundremoval;
      });
      obs-vkcapture = prev.obs-studio-plugins.obs-vkcapture.overrideAttrs (_: {
        src = sources.obs-vkcapture;
      });
      obs-pipewire-audio-capture = prev.obs-studio-plugins.obs-pipewire-audio-capture.overrideAttrs (_: {
        src = sources.obs-pipewire-audio-capture;
      });
      obs-image-reaction = prev.callPackage ({
        stdenv,
        cmake,
        obs-studio,
      }:
        stdenv.mkDerivation rec {
          pname = "obs-image-reaction";
          version = "1.3";
          src = sources.obs-image-reaction;
          nativeBuildInputs = [cmake];
          buildInputs = [obs-studio];
          postInstall = ''
            mkdir $out/lib $out/share
            mv $out/obs-plugins/64bit $out/lib/obs-plugins
            rm -rf $out/obs-plugins
            mv $out/data $out/share/obs
          '';
        }) {};
    };
}

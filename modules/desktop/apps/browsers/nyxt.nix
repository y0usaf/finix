{
  lib,
  pkgs,
  ...
}: let
  pname = "nyxt";
  version = "5.0.0-pre-release-2";
  src = pkgs.fetchurl {
    url = "https://github.com/atlas-engineer/nyxt/releases/download/${version}/Nyxt-${version}-x86_64.AppImage";
    hash = "sha256-JIEtcYvntHYA0qCHiraAIxLcxUFyQr7eWfezBcWxryY=";
  };
  contents = pkgs.appimageTools.extract {inherit pname version src;};
  nyxt = pkgs.appimageTools.wrapType2 {
    inherit pname version src;
    extraInstallCommands = ''
      for desktop in ${contents}/*.desktop; do
        install -Dm444 "$desktop" "$out/share/applications/nyxt.desktop"
      done
      substituteInPlace "$out/share/applications/nyxt.desktop" --replace-quiet 'Exec=AppRun' "Exec=$out/bin/nyxt"
    '';
    meta = {
      description = "Nyxt 5 pre-release (CEF/Chromium engine), from the upstream AppImage";
      homepage = "https://nyxt.atlas.engineer";
      license = lib.licenses.bsd3;
      platforms = ["x86_64-linux"];
      mainProgram = "nyxt";
    };
  };
in {
  environment.systemPackages = [nyxt];
  system.build.nyxt = nyxt;
  user.persist.directories = [
    ".config/nyxt"
    ".local/share/nyxt"
    ".cache/nyxt"
  ];
}

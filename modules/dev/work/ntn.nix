{
  lib,
  pkgs,
  ...
}: let
  version = "0.22.10";
  distDir = "ntn-linux-x64";
in {
  environment.systemPackages = [
    (pkgs.stdenvNoCC.mkDerivation {
      pname = "ntn";
      inherit version;

      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/ntn/-/ntn-${version}.tgz";
        hash = "sha256-9QWWmG52HgAdG7CRMdX5C8eIxYvJnL5QCqLP1rTjww8=";
      };

      dontUnpack = true;
      dontPatchELF = true;
      dontStrip = true;
      installPhase = ''
        runHook preInstall
        mkdir -p $out/bin $out/share/licenses/ntn
        tar -xzf $src package/dist/${distDir}/ntn package/LICENSE.md
        install -m755 package/dist/${distDir}/ntn $out/bin/ntn
        cp package/LICENSE.md $out/share/licenses/ntn/LICENSE.md
        runHook postInstall
      '';

      meta = {
        description = "Official CLI for Notion";
        homepage = "https://developers.notion.com/cli";
        license = lib.licenses.mit;
        mainProgram = "ntn";
        platforms = [
          "x86_64-linux"
          "aarch64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
        ];
      };
    })
  ];
}

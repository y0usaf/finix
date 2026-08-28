{
  config,
  lib,
  pkgs,
  ...
}: let
  version = "0.22.10";
  # dist/ directory inside the npm tarball for the host platform; each holds a
  # statically linked binary, so no launcher or runtime deps are needed.
  distDir = {
    x86_64-linux = "ntn-linux-x64";
    aarch64-linux = "ntn-linux-arm64";
    x86_64-darwin = "ntn-darwin-x64";
    aarch64-darwin = "ntn-darwin-arm64";
  }.${pkgs.stdenv.hostPlatform.system};
in {
  options.user.dev.work.ntn = {
    enable = lib.mkEnableOption "Notion CLI (ntn)";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.stdenvNoCC.mkDerivation {
        pname = "ntn";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://registry.npmjs.org/ntn/-/ntn-${version}.tgz";
          hash = "sha256-9QWWmG52HgAdG7CRMdX5C8eIxYvJnL5QCqLP1rTjww8=";
        };

        dontUnpack = true;
        # Prebuilt static binary: skip ELF patching and stripping.
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
      };
      description = "Notion CLI (ntn) package to install.";
    };
  };

  config = lib.mkIf config.user.dev.work.ntn.enable {
    environment.systemPackages = [
      config.user.dev.work.ntn.package
    ];
  };
}
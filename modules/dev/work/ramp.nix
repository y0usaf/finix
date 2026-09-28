{
  config,
  lib,
  pkgs,
  ...
}: let
  version = "0.2.27";
in {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/ramp"
  ];
  environment.systemPackages = [
    (pkgs.stdenvNoCC.mkDerivation {
      pname = "ramp";
      inherit version;

      src = pkgs.fetchurl {
        url = "https://github.com/ramp-public/ramp-cli/releases/download/v${version}/ramp-linux-amd64.tar.gz";
        hash = "sha256-xccIbLXdDAPmWFRzD/fGC4Co89ivgo6891/Q8ZG5J1c=";
      };

      nativeBuildInputs = [pkgs.autoPatchelfHook];
      buildInputs = [pkgs.zlib];

      dontStrip = true;
      installPhase = ''
        runHook preInstall
        mkdir -p $out/share/ramp $out/bin
        cp -r . $out/share/ramp/main.dist
        ln -s $out/share/ramp/main.dist/ramp-linux-amd64 $out/bin/ramp
        runHook postInstall
      '';

      meta = {
        description = "CLI for the Ramp spend management platform";
        homepage = "https://github.com/ramp-public/ramp-cli";
        license = lib.licenses.mit;
        mainProgram = "ramp";
        platforms = ["x86_64-linux"];
        sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      };
    })
  ];
}

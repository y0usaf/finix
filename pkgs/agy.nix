{pkgs}: let
  inherit (pkgs) lib;
  version = "1.5.12";
in
  pkgs.stdenvNoCC.mkDerivation {
    pname = "agy";
    inherit version;
    src = pkgs.fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${version}-5281398513336320/linux-x64/cli_linux_x64.tar.gz";
      sha512 = "26de25fccb3fbf0b093e090ce14a14ac1df1ec3e90ef4ea6106887d3a81b0cc9edb0dadea7b9101d07f9606eba159062a6fb7b78e91b73f7520684a24db73428";
    };
    nativeBuildInputs = [pkgs.patchelf];
    sourceRoot = ".";
    installPhase = ''
      runHook preInstall
      install -Dm755 antigravity $out/bin/agy
      patchelf --set-interpreter ${pkgs.stdenv.cc.bintools.dynamicLinker} --set-rpath ${lib.makeLibraryPath [pkgs.stdenv.cc.libc]} $out/bin/agy
      runHook postInstall
    '';
    dontFixup = true;
    meta = {
      description = "Google Antigravity CLI, the agy binary omp's antigravity-cli provider drives over ACP";
      homepage = "https://antigravity.google";
      license = lib.licenses.unfree;
      platforms = ["x86_64-linux"];
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      mainProgram = "agy";
    };
  }

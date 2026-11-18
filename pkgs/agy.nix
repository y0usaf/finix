{pkgs}: let
  inherit (pkgs) lib;
  version = "1.5.11";
in
  pkgs.stdenvNoCC.mkDerivation {
    pname = "agy";
    inherit version;
    src = pkgs.fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${version}-6132547114106880/linux-x64/cli_linux_x64.tar.gz";
      sha512 = "dad3c015e8964fcdc1639b13b7152f4cb84cb1bde385707e2bcdf095d6f1831f4f6521199aec499cc052f9e99906b7fdbc52c273df064d5cb7c84b068ba3ce50";
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

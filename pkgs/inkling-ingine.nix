{
  pkgs,
  cudaArch ? "89",
}: let
  inherit (pkgs) cudaPackages lib;
in
  cudaPackages.backendStdenv.mkDerivation {
    pname = "inkling-ingine";
    version = "0-unstable-2026-11-21";

    src = pkgs.fetchFromGitHub {
      owner = "skyne98";
      repo = "inkling-ingine-3090";
      rev = "c0742fc1fca1e1681953795cac21e9d5a4f26856";
      hash = "sha256-iCITX+70kFCgYW+d1ihBL5CQHB6FKfmwVgWy4kmnCF0=";
    };

    patches = [./inkling-ingine-sm89.patch];

    cmakeDir = "../native";

    nativeBuildInputs = [
      pkgs.cmake
      pkgs.ninja
      cudaPackages.cuda_nvcc
      pkgs.autoAddDriverRunpath
    ];

    buildInputs = [
      cudaPackages.cuda_cudart
      cudaPackages.cccl
      cudaPackages.nvtx
      cudaPackages.libcublas
    ];

    cmakeFlags = [
      (lib.cmakeFeature "CMAKE_BUILD_TYPE" "Release")
      (lib.cmakeFeature "CMAKE_CUDA_ARCHITECTURES" cudaArch)
      (lib.cmakeBool "INGINE_BUILD_TESTS" false)
    ];

    installPhase = ''
      runHook preInstall
      install -Dm755 apps/serve/ingine-serve $out/bin/ingine-serve
      install -Dm755 apps/bench/ingine-bench $out/bin/ingine-bench
      install -Dm755 apps/validate/ingine-validate $out/bin/ingine-validate
      runHook postInstall
    '';

    meta = {
      description = "CUDA inference engine for Inkling-2-Mini (abliterated) with Ada sm_89 support";
      homepage = "https://github.com/skyne98/inkling-ingine-3090";
      license = lib.licenses.asl20;
      platforms = ["x86_64-linux"];
      mainProgram = "ingine-serve";
    };
  }

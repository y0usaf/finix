{
  pkgs,
  cudaArch ? "89",
}: let
  inherit (pkgs) cudaPackages lib;
in
  cudaPackages.backendStdenv.mkDerivation {
    pname = "inkling-ingine";
    version = "0-unstable-2026-11-25";

    src = pkgs.fetchFromGitHub {
      owner = "satellitedown";
      repo = "inkling-2-mini-abliterated-ingine";
      rev = "556acc7cf42749536684854a6df820e41258f929";
      hash = "sha256-Lhkv96bX4/IOeFWLHpo5WXaAZKwGcI3obARaXdLaQhg=";
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
      description = "CUDA inference engine for Inkling-2-Mini (abliterated) ported to Ada sm_89";
      homepage = "https://github.com/satellitedown/inkling-2-mini-abliterated-ingine";
      license = lib.licenses.asl20;
      platforms = ["x86_64-linux"];
      mainProgram = "ingine-serve";
    };
  }

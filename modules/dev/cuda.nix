#===============================================================================
#                      🚀 CUDA Development Configuration 🚀
#===============================================================================
# 🧠 NVIDIA CUDA Toolkit
# 🔧 Development libraries and tools
# 🛠️ Environment configuration
#===============================================================================
{
  config,
  pkgs,
  lib,
  profile,
  ...
}: {
  config = {
    # Install CUDA development packages
    home.packages = with pkgs; [
      # Core CUDA toolkit
      cudaPackages.cudatoolkit
      # Development tools
      cudaPackages.cuda_nvcc
      # Additional libraries
      cudaPackages.libcublas
      cudaPackages.libcufft
      cudaPackages.libcurand
      cudaPackages.libcusparse
      # Debugging and profiling
      cudaPackages.cuda_gdb
    ];

    # Set CUDA environment variables
    home.sessionVariables = {
      CUDA_PATH = "${pkgs.cudaPackages.cudatoolkit}";
      CUDA_HOME = "${pkgs.cudaPackages.cudatoolkit}";
      # Add CUDA to library path
      LD_LIBRARY_PATH =
        lib.makeLibraryPath [
          "${pkgs.cudaPackages.cudatoolkit}/lib"
          "${pkgs.cudaPackages.libcublas}/lib"
        ]
        + ":$LD_LIBRARY_PATH";
    };

    # Add CUDA to PATH
    home.sessionPath = [
      "${pkgs.cudaPackages.cudatoolkit}/bin"
    ];

    # Add CUDA environment variables to shell
    programs.zsh = {
      envExtra = ''
        # CUDA environment setup
        export CUDA_PATH="${pkgs.cudaPackages.cudatoolkit}"
        export CUDA_HOME="${pkgs.cudaPackages.cudatoolkit}"

        # Add CUDA libraries to library path
        export LD_LIBRARY_PATH="${lib.makeLibraryPath [
          "${pkgs.cudaPackages.cudatoolkit}/lib"
          "${pkgs.cudaPackages.libcublas}/lib"
        ]}:$LD_LIBRARY_PATH"

        # Set compiler flags for CUDA
        export CPATH="${pkgs.cudaPackages.cudatoolkit}/include:$CPATH"
        export LIBRARY_PATH="${pkgs.cudaPackages.cudatoolkit}/lib:$LIBRARY_PATH"
      '';
    };

    # Create XDG directories for CUDA
    home.activation.createCudaDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p ${config.xdg.cacheHome}/nv
      $DRY_RUN_CMD mkdir -p ${config.xdg.cacheHome}/nvidia
      $DRY_RUN_CMD mkdir -p ${config.xdg.dataHome}/cuda
    '';
  };
}

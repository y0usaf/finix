###############################################################################
# CUDA Development Module
# Configuration for NVIDIA CUDA development environment
# - CUDA Toolkit and development libraries
# - Environment variables for CUDA development
# - Library paths and compiler settings
###############################################################################
{
  config,
  pkgs,
  lib,
  hostSystem,
  hostHome,
  ...
}: let
  cfg = config.cfg.core.nvidia.cuda;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.core.nvidia.cuda = {
    enable = lib.mkEnableOption "CUDA development environment";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
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

    ###########################################################################
    # Environment Variables
    ###########################################################################
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

    ###########################################################################
    # Activation Scripts
    ###########################################################################
    home.activation.createCudaDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p ${config.xdg.cacheHome}/nv
      $DRY_RUN_CMD mkdir -p ${config.xdg.cacheHome}/nvidia
      $DRY_RUN_CMD mkdir -p ${config.xdg.dataHome}/cuda
    '';
  };
}

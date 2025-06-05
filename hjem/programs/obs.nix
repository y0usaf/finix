###############################################################################
# OBS Studio Module
# Configuration for OBS Studio (Open Broadcaster Software)
# - Video recording and live streaming
# - Plugin support for background removal and Vulkan capture
# - Custom image reaction plugin
# - Conditional CUDA support when NVIDIA is enabled
###############################################################################
{
  config,
  pkgs,
  lib,
  inputs,
  hostSystem,
  ...
}: let
  cfg = config.cfg.hjome.programs.obs;

  # Check if NVIDIA and CUDA are enabled in the system configuration
  nvidiaCudaEnabled = hostSystem.cfg.hardware.nvidia.enable && (hostSystem.cfg.hardware.nvidia.cuda.enable or false);

  # Create a CUDA-enabled OBS package if NVIDIA and CUDA are enabled
  obsPackage =
    if nvidiaCudaEnabled
    then pkgs.obs-studio.override {cudaSupport = true;}
    else pkgs.obs-studio;

  # Create a customized background removal plugin with CUDA properly configured
  customBackgroundRemoval = pkgs.obs-studio-plugins.obs-backgroundremoval.overrideAttrs (oldAttrs: {
    cmakeFlags =
      oldAttrs.cmakeFlags
      ++ [
        # Explicitly specify CUDA paths
        "-DCUDA_TOOLKIT_ROOT_DIR=${pkgs.cudaPackages.cudatoolkit}"
        # Disable GPU components that are causing issues
        "-DDISABLE_ONNXRUNTIME_GPU=ON"
      ];
  });
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.hjome.programs.obs = {
    enable = lib.mkEnableOption "OBS Studio";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    packages = with pkgs; [
      # Main OBS package with conditional CUDA support
      obsPackage

      # OBS plugins
      obs-studio-plugins.obs-backgroundremoval
      obs-studio-plugins.obs-vkcapture
      inputs.obs-image-reaction.packages.${pkgs.system}.default

      # Additional utilities
      v4l-utils
    ];
  };
}

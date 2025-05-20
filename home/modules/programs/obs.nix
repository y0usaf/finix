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
  cfg = config.cfg.programs.obs;

  # Check if NVIDIA and CUDA are enabled in the system configuration
  nvidiaCudaEnabled = hostSystem.cfg.hardware.nvidia.enable && (hostSystem.cfg.hardware.nvidia.cuda.enable or false);
  
  # Create a CUDA-enabled OBS package if NVIDIA and CUDA are enabled
  obsPackage = if nvidiaCudaEnabled 
    then pkgs.obs-studio.override { cudaSupport = true; }
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
  options.cfg.programs.obs = {
    enable = lib.mkEnableOption "OBS Studio";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Programs
    ###########################################################################
    programs.obs-studio = {
      enable = true;
      # Use the CUDA-enabled package if NVIDIA+CUDA are enabled
      package = obsPackage;
      plugins = with pkgs.obs-studio-plugins; [
        customBackgroundRemoval
        obs-vkcapture
        inputs.obs-image-reaction.packages.${pkgs.system}.default
      ];
    };
    home.packages = with pkgs; [v4l-utils];
  };
}

###############################################################################
# OBS Studio Module
# Configuration for OBS Studio (Open Broadcaster Software)
# - Video recording and live streaming
# - Plugin support for background removal and Vulkan capture
# - Custom image reaction plugin
###############################################################################
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  cfg = config.cfg.programs.obs;

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
      plugins = with pkgs.obs-studio-plugins; [
        customBackgroundRemoval
        obs-vkcapture
        inputs.obs-image-reaction.packages.${pkgs.system}.default
      ];
    };
  };
}

{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.hardware.nvidia.enable {
    environment = {
      systemPackages = [
        pkgs.cudaPackages.cudnn
      ];
      variables = {
        __GL_SYNC_TO_VBLANK = "0";
        __GL_VRR_ALLOWED = "1";
        __GL_MaxFramesAllowed = "1";
        __GL_YIELD = "usleep";
        CUDA_DISABLE_PERF_BOOST = "1";
        NVIDIA_DRIVER_CAPABILITIES = "all";
      };
      etc."nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool.json".text = lib.generators.toJSON {} {
        rules = [
          {
            pattern = {
              feature = "true";
              matches = "";
            };
            profile = "No VidMem Reuse";
          }
          {
            pattern = {
              feature = "true";
              matches = "";
            };
            profile = "CudaNoStablePerfLimit";
          }
        ];
      };
    };
  };
}

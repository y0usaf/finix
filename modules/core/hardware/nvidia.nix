{
  config,
  lib,
  pkgs,
  ...
}: {
  # Only the environment.* subtree survives the compat shim. NVIDIA_DRIVER,
  # kernel-modules, firmware-driver, nixpkgs.cudaSupport, boot params and the
  # polkit rule were NixOS-only and are dropped — finix installs the driver
  # natively (hosts/.../finix/graphical.nix). options.hardware.nvidia is owned
  # by finix and must not be declared here. Guard reads finix's stub.
  config = lib.mkIf config.hardware.nvidia.enable {
    environment = {
      systemPackages = [
        pkgs.cudaPackages.cudnn
      ];
      # sessionVariables was re-homed to variables (compat remap).
      variables = {
        __GL_SYNC_TO_VBLANK = "0";
        __GL_VRR_ALLOWED = "1";
        __GL_MaxFramesAllowed = "1";
        __GL_YIELD = "usleep";
        CUDA_CACHE_PATH = "${config.user.homeDirectory}/.cache/nv";
        CUDA_DISABLE_PERF_BOOST = "1";
        NVIDIA_DRIVER_CAPABILITIES = "all";
        WAYDROID_EXTRA_ARGS = "--gpu-mode host";
      };
      # Fix high VRAM usage on electron apps
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
{
  config,
  lib,
  pkgs,
  ...
}: let
  homeDir = config.user.homeDirectory;
in {
  options.user.dev.upscale = {
    enable = lib.mkEnableOption "realesrgan-ncnn-vulkan for upscaling";
  };

  config = lib.mkIf config.user.dev.upscale.enable {
    environment.systemPackages = [
      pkgs.realesrgan-ncnn-vulkan
    ];
    user.shell.rcExtra = lib.mkAfter ''
      alias esrgan="realesrgan-ncnn-vulkan -i ${homeDir}/Pictures/Upscale/Input -o ${homeDir}/Pictures/Upscale/Output"
    '';
  };
}

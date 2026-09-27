{
  config,
  lib,
  pkgs,
  ...
}: let
  homeDir = config.user.homeDirectory;
in {
  environment.systemPackages = [
    pkgs.realesrgan-ncnn-vulkan
  ];
  user.shell.rcExtra = lib.mkAfter ''
    alias esrgan="realesrgan-ncnn-vulkan -i ${homeDir}/Pictures/Upscale/Input -o ${homeDir}/Pictures/Upscale/Output"
  '';
}

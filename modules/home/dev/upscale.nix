{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.dev.upscale;
in {
  options.home.dev.upscale = {
    enable = lib.mkEnableOption "realesrgan-ncnn-vulkan for upscaling";
  };

  config = lib.mkIf cfg.enable {
    users.users.${config.user.name}.maid = {
      packages = with pkgs; [
        realesrgan-ncnn-vulkan
      ];
      file.home.".config/zsh/aliases/esrgan.zsh".text = ''
        alias esrgan="realesrgan-ncnn-vulkan -i ${config.user.homeDirectory}/Pictures/Upscale/Input -o ${config.user.homeDirectory}/Pictures/Upscale/Output"
      '';
    };
  };
}

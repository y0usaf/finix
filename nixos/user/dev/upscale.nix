{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.dev.upscale = {
    enable = lib.mkEnableOption "realesrgan-ncnn-vulkan for upscaling";
  };

  config = lib.mkIf config.user.dev.upscale.enable {
    environment.systemPackages = [
      pkgs.realesrgan-ncnn-vulkan
    ];
    bayt.users."${config.user.name}".files =
      lib.optionalAttrs config.user.shell.zsh.enable {
        ".config/zsh/aliases/esrgan.zsh" = {
          text = ''
            alias esrgan="realesrgan-ncnn-vulkan -i ${config.user.homeDirectory}/Pictures/Upscale/Input -o ${config.user.homeDirectory}/Pictures/Upscale/Output"
          '';
          clobber = true;
        };
      }
      // lib.optionalAttrs config.user.shell.nushell.enable {
        ".config/nushell/config.nu" = {
          text = lib.mkAfter ''
            alias esrgan = realesrgan-ncnn-vulkan -i ${config.user.homeDirectory}/Pictures/Upscale/Input -o ${config.user.homeDirectory}/Pictures/Upscale/Output
          '';
          clobber = true;
        };
      };
  };
}

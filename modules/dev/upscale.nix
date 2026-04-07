{
  config,
  lib,
  pkgs,
  ...
}: let
  zshEnabled = lib.attrByPath ["user" "shell" "zsh" "enable"] false config;
  nushellEnabled = lib.attrByPath ["user" "shell" "nushell" "enable"] false config;
  homeDir = config.user.homeDirectory;
in {
  options.user.dev.upscale = {
    enable = lib.mkEnableOption "realesrgan-ncnn-vulkan for upscaling";
  };

  config = lib.mkIf config.user.dev.upscale.enable {
    environment.systemPackages = [
      pkgs.realesrgan-ncnn-vulkan
    ];
    bayt.users."${config.user.name}".files =
      lib.optionalAttrs zshEnabled {
        ".config/zsh/aliases/esrgan.zsh" = {
          text = ''
            alias esrgan="realesrgan-ncnn-vulkan -i ${homeDir}/Pictures/Upscale/Input -o ${homeDir}/Pictures/Upscale/Output"
          '';
        };
      }
      // lib.optionalAttrs nushellEnabled {
        ".config/nushell/config.nu" = {
          text = lib.mkAfter ''
            alias esrgan = realesrgan-ncnn-vulkan -i ${homeDir}/Pictures/Upscale/Input -o ${homeDir}/Pictures/Upscale/Output
          '';
        };
      };
  };
}

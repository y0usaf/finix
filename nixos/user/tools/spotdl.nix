{
  config,
  pkgs,
  lib,
  ...
}: {
  options.user.tools.spotdl = {
    enable = lib.mkEnableOption "SpotDL music downloading tools";
  };
  config = lib.mkIf config.user.tools.spotdl.enable {
    environment.systemPackages = [
      pkgs.ffmpeg
    ];
    usr = {
      files = lib.optionalAttrs config.user.shell.zsh.enable {
        ".config/zsh/.zshrc" = {
          text = lib.mkAfter ''
            alias spotm4a="uvx spotdl --format m4a --output '{title}'"
            alias spotmp3="uvx spotdl --format mp3 --output '{title}'"
          '';
          clobber = true;
        };
      };
    };
  };
}

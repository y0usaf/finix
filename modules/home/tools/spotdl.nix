{
  config,
  pkgs,
  lib,
  ...
}: {
  options.home.tools.spotdl = {
    enable = lib.mkEnableOption "SpotDL music downloading tools";
  };
  config = lib.mkIf config.home.tools.spotdl.enable {
    environment.systemPackages = [
      pkgs.ffmpeg
    ];
    usr = {
      files = {
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

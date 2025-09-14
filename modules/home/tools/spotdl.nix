{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.tools.spotdl;
in {
  options.home.tools.spotdl = {
    enable = lib.mkEnableOption "SpotDL music downloading tools";
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      ffmpeg
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

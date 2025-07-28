{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.tools.yt-dlp;
in {
  options.home.tools.yt-dlp = {
    enable = lib.mkEnableOption "YouTube-DLP media conversion tools";
  };
  config = lib.mkIf cfg.enable {
    users.users.${config.user.name}.maid = {
      packages = with pkgs; [
        yt-dlp-light
        ffmpeg
      ];
    };
    hjem.users.${config.user.name}.files = {
      ".config/zsh/.zshrc" = {
        text = lib.mkAfter ''
          alias ytm4a="yt-dlp --extractor-args 'youtube:player_client=android' --no-check-certificate -x --audio-format m4a --embed-metadata --add-metadata -o '%(title)s.%(ext)s'"
          alias ytmp3="yt-dlp --extractor-args 'youtube:player_client=android' --no-check-certificate -x --audio-format mp3 --embed-metadata --add-metadata -o '%(title)s.%(ext)s'"
          alias ytmp4="yt-dlp --extractor-args 'youtube:player_client=android' --no-check-certificate -f 'bv*[height<=720]+ba/b[height<=720]' --recode-video mp4 --embed-metadata --add-metadata --postprocessor-args 'ffmpeg:-c:v libx264 -crf 23 -preset medium -c:a aac -b:a 128k -vf scale=-2:720' -o '%(title)s.%(ext)s'"
          alias ytmp4s="yt-dlp --extractor-args 'youtube:player_client=android' --no-check-certificate -f 'bv*[height<=480]+ba/b[height<=480]' --recode-video mp4 --embed-metadata --add-metadata --postprocessor-args 'ffmpeg:-c:v libx264 -crf 26 -preset faster -c:a aac -b:a 96k -vf scale=-2:480' -o '%(title)s.%(ext)s'"
          alias ytwebm="yt-dlp --extractor-args 'youtube:player_client=android' --no-check-certificate -f 'bv*[height<=720]+ba/b[height<=720]' --recode-video webm --embed-metadata --add-metadata --postprocessor-args 'ffmpeg:-c:v libvpx-vp9 -crf 30 -b:v 0 -c:a libopus -vf scale=-2:720' -o '%(title)s.%(ext)s'"
          alias ytdiscord="yt-dlp --extractor-args 'youtube:player_client=android' --no-check-certificate -f 'bv*[height<=720]+ba/b[height<=720]' --recode-video mp4 --embed-metadata --add-metadata --postprocessor-args 'ffmpeg:-c:v libx264 -crf 28 -preset faster -c:a aac -b:a 96k -vf scale=-2:min(720,ih) -fs 7.8M' -o '%(title)s_discord.%(ext)s'"
        '';
        clobber = true;
      };
    };
  };
}

{lib, ...}: {
  user.tools = {
    git.enable = lib.mkDefault true;
    gh.enable = lib.mkDefault true;
    nh.enable = lib.mkDefault true;
    "7z".enable = lib.mkDefault true;
    file-roller.enable = lib.mkDefault true;
    yt-dlp.enable = lib.mkDefault true;
  };
}

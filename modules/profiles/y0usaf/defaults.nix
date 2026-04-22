{lib, ...}: {
  user.defaults = {
    browser = "librewolf";
    editor = lib.mkDefault "nvim";
    ide = lib.mkDefault "cursor";
    terminal = lib.mkDefault "foot";
    fileManager = lib.mkDefault "pcmanfm";
    launcher = lib.mkDefault "foot --app-id=launcher ~/.config/scripts/tui-launcher.sh";
    discord = lib.mkDefault "discord";
    archiveManager = lib.mkDefault "file-roller";
    imageViewer = lib.mkDefault "imv";
    mediaPlayer = lib.mkDefault "mpv";
  };
}

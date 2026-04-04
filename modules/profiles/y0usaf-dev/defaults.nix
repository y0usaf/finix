{lib, ...}: {
  user.defaults = {
    browser = "librewolf";
    editor = lib.mkDefault "nvim";
    ide = lib.mkDefault "cursor";
    terminal = lib.mkDefault "termvide";
    fileManager = lib.mkDefault "pcmanfm";
    launcher = lib.mkDefault "foot -a 'launcher' ~/.config/scripts/tui-launcher.sh";
    discord = lib.mkDefault "discord-canary";
    archiveManager = lib.mkDefault "file-roller";
    imageViewer = lib.mkDefault "imv";
    mediaPlayer = lib.mkDefault "mpv";
  };
}

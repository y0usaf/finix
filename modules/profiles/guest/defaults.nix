{lib, ...}: {
  user.defaults = {
    browser = lib.mkDefault "librewolf";
    editor = lib.mkDefault "nvim";
    terminal = lib.mkDefault "foot";
    fileManager = lib.mkDefault "pcmanfm";
    launcher = lib.mkDefault "foot -a 'launcher' ~/.config/scripts/tui-launcher.sh";
    archiveManager = lib.mkDefault "file-roller";
    imageViewer = lib.mkDefault "imv";
    mediaPlayer = lib.mkDefault "mpv";
  };
}

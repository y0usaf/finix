{lib, ...}: {
  user.programs = {
    webapps.enable = lib.mkDefault true;
    keybard.enable = lib.mkDefault true;
    google-meet.enable = lib.mkDefault true;
    gcp-console.enable = lib.mkDefault true;
    linear.enable = lib.mkDefault true;
    librewolf.enable = lib.mkDefault true;
    codex-desktop = {
      enable = lib.mkDefault false;
      yoloMode = lib.mkDefault true;
    };
    discord = {
      stable.enable = lib.mkDefault true;
      vesktop.enable = lib.mkDefault true;
    };
    obsidian.enable = lib.mkDefault true;
    bluetooth.enable = lib.mkDefault true;
    imv.enable = lib.mkDefault true;
    mimeapps.enable = lib.mkDefault true;
    mpv.enable = lib.mkDefault true;
    pcmanfm.enable = lib.mkDefault true;
    rudo.enable = lib.mkDefault true;
    stremio.enable = lib.mkDefault true;
    tui-launcher.enable = lib.mkDefault true;
    slack.enable = lib.mkDefault true;
    btop.enable = lib.mkDefault true;
  };
}

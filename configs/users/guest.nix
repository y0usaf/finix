{
  pkgs,
  lib,
  ...
}: {
  users.users.guest = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = ["networkmanager" "video" "audio"];
    home = "/home/guest";
    ignoreShellProgramCheck = true;
  };
  user = {
    defaults = {
      browser = lib.mkDefault "librewolf";
      editor = lib.mkDefault "nvim";
      terminal = lib.mkDefault "foot";
      fileManager = lib.mkDefault "pcmanfm";
      launcher = lib.mkDefault "foot -a 'launcher' ~/.config/scripts/tui-launcher.sh";
      archiveManager = lib.mkDefault "file-roller";
      imageViewer = lib.mkDefault "imv";
      mediaPlayer = lib.mkDefault "mpv";
    };
    appearance = {
      dpi = 144;
      baseFontSize = 12;
      cursorSize = 36;
    };
    paths = {
      music.path = "/home/guest/Music";
      dcim.path = "/home/guest/DCIM";
    };
    ui = {
      cursor.enable = true;
      fonts.enable = true;
      foot.enable = true;
      gtk.enable = true;
      hyprland = {
        enable = false;
      };
      wayland.enable = true;
    };
    programs = {
      firefox.enable = false;
      librewolf.enable = true;
      media.enable = true;
      imv.enable = true;
      mpv.enable = true;
      pcmanfm.enable = true;
    };
    shell = {
      zsh.enable = true;
      cat-fetch.enable = true;
    };
    tools = {
      "7z".enable = true;
      file-roller.enable = true;
    };
    services = {
      polkitAgent.enable = true;
    };
  };
}

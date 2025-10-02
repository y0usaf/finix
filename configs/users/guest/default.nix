{
  pkgs,
  lib,
  ...
}: {
  # Direct NixOS user configuration
  users.users.guest = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = ["networkmanager" "video" "audio"];
    home = "/home/guest";
    ignoreShellProgramCheck = true;
  };
  home = {
    core = {
      packages.enable = true;
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
        enable = true;
        dpi = 144;
        baseFontSize = 12;
        cursorSize = 36;
        fonts = {
          main = [
            {
              package = pkgs.fastFonts;
              name = "Fast IosevkaSlab";
            }
          ];
          fallback = [
            {
              package = pkgs.noto-fonts-emoji;
              name = "Noto Color Emoji";
            }
            {
              package = pkgs.noto-fonts-cjk-sans;
              name = "Noto Sans CJK";
            }
            {
              package = pkgs.font-awesome;
              name = "Font Awesome";
            }
          ];
        };
      };
      user.enable = true;
    };
    directories = {
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

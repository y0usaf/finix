{
  pkgs,
  inputPackages,
  ...
}: {
  environment.systemPackages = [
    pkgs.nixos-icons
    pkgs.playerctl
    pkgs.pulsemixer
    pkgs.xdg-utils
    pkgs.polkit_gnome
    pkgs.gvfs
    pkgs.pcmanfm
    pkgs.mpv
    pkgs.ffmpeg
    pkgs.vlc
    pkgs.imv
    inputPackages.emeraldian.default
  ];
}

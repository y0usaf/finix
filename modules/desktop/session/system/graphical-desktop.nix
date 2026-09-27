{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.nixos-icons
    pkgs.playerctl
    pkgs.pulsemixer
    pkgs.xdg-utils
  ];
}

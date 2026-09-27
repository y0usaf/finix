{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.wget
    pkgs.cachix
    pkgs.unzip
    pkgs.lsd
    pkgs.tree
    pkgs.psmisc
    pkgs.lm_sensors
    pkgs.fzf
    pkgs.ripgrep
  ];
}

{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.git
    pkgs.curl
    pkgs.wget
    pkgs.cachix
    pkgs.unzip
    pkgs.bash
    pkgs.lsd
    pkgs.tree
    pkgs.psmisc
    pkgs.lm_sensors
    pkgs.fzf
    pkgs.ripgrep
  ];
}

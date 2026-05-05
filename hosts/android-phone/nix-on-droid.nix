{pkgs, ...}: {
  system.stateVersion = "24.05";

  environment.packages = with pkgs; [
    bashInteractive
    coreutils
    curl
    fd
    git
    jq
    nano
    openssh
    ripgrep
    vim
    wget
    which
    zellij
    zsh
  ];

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
}

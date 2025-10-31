{...}: {
  imports = [
    ./zsh.nix
    ./zellij
  ];

  # Enable zsh system-wide
  programs.zsh.enable = true;
}

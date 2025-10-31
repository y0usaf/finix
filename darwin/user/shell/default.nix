{...}: {
  imports = [
    ./zsh.nix
    ./zellij
  ];

  programs.zsh.enable = true;
}

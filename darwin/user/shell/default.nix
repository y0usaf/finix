{...}: {
  imports = [
    ./zsh.nix
    ./nushell.nix
    ./zellij
  ];

  # Enable zsh system-wide
  programs.zsh.enable = true;
}

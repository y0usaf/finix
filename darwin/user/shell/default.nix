{...}: {
  imports = [
    ./zsh
    ./nushell
  ];

  # Enable zsh system-wide
  programs.zsh.enable = true;
}

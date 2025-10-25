{pkgs, ...}: {
  # Shell configuration
  environment.systemPackages = with pkgs; [
    nushell
    zsh
  ];

  programs.zsh.enable = true;
}

{pkgs, ...}: {
  # Core system packages
  environment.systemPackages = with pkgs; [
    vim
    git
    nh
    claude-code
    raycast
    kitty
  ];
}

{
  config,
  pkgs,
  nvf,
  ...
}: let
  basePackages = with pkgs; [
    # Core tools
    vim
    git
    nh
    claude-code
    raycast
    alacritty
    nushell
    alejandra

    # CLI utilities
    bat
    lsd
    tree
    ripgrep
    statix
    deadnix
    zellij

    # Input remapping
    karabiner-elements

    # UI/System tools
    alt-tab-macos
    discord

    # Neovim via nvf
    nvf.packages.${pkgs.system}.default
  ];
in {
  # Core system packages with support for extra packages via options
  environment.systemPackages = basePackages ++ config.user.packages.extraPackages;
}

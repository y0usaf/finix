{
  config,
  pkgs,
  nvf,
  ...
}: let
  basePackages = with pkgs; [
    vim
    git
    nh
    raycast
    alacritty
    alejandra
    bun

    bat
    lsd
    tree
    ripgrep
    statix
    deadnix
    zellij

    karabiner-elements

    alt-tab-macos
    discord

    nvf.packages.${pkgs.system}.default
  ];
in {
  imports = [
    ./user-config.nix
  ];

  environment.systemPackages = basePackages ++ config.user.packages.extraPackages;
}

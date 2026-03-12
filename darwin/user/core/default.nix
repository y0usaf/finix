{
  config,
  pkgs,
  nvf,
  ...
}: {
  imports = [
    ./user-config.nix
    ./strictix.nix
  ];

  environment.systemPackages =
    [
      pkgs.vim
      pkgs.git
      pkgs.nh
      pkgs.raycast
      pkgs.alacritty
      pkgs.alejandra
      pkgs.bun

      pkgs.bat
      pkgs.lsd
      pkgs.tree
      pkgs.ripgrep
      pkgs.statix
      pkgs.deadnix
      pkgs.zellij

      pkgs.karabiner-elements

      pkgs.alt-tab-macos
      pkgs.discord

      nvf.packages."${pkgs.stdenv.hostPlatform.system}".default
    ]
    ++ config.user.packages.extraPackages;
}

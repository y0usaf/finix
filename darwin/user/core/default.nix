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
    (with pkgs; [
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

      nvf.packages.${pkgs.stdenv.hostPlatform.system}.default
    ])
    ++ config.user.packages.extraPackages;
}

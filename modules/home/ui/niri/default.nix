{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./options.nix
    ./config.nix
    ./input.nix
    ./monitors.nix
    ./layout.nix
    ./keybindings.nix
    ./environment.nix
    ./portals.nix
  ];

  config = lib.mkIf config.home.ui.niri.enable {
    environment.systemPackages = [
      pkgs.xwayland-satellite
    ];
  };
}

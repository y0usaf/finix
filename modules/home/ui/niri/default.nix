{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.ui.niri;
in {
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

  config = lib.mkIf cfg.enable {
    usr.packages = with pkgs; [
      xwayland-satellite
    ];
  };
}

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
  ];

  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name}.packages = with pkgs; [
      xwayland-satellite
    ];
  };
}

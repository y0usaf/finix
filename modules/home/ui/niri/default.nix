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
    users.users.${config.user.name}.maid.packages = with pkgs; [
      xwayland-satellite
    ];
  };
}

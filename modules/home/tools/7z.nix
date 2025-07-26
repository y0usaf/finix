{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.tools."7z";
in {
  options.home.tools."7z" = {
    enable = lib.mkEnableOption "7z (p7zip) archive manager";
  };
  config = lib.mkIf cfg.enable {
    # nix-maid (legacy)
    users.users.${config.user.name}.maid.packages = with pkgs; [
      p7zip
    ];
    # hjem (new)
    hjem.users.${config.user.name}.packages = with pkgs; [
      p7zip
    ];
  };
}

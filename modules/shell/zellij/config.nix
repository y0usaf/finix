{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.user.shell.zellij.enable {
    environment.systemPackages = [
      pkgs.zellij
    ];
  };
}

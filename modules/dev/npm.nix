{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.dev.npm = {
    enable = lib.mkEnableOption "Node.js and NPM configuration";
  };
  config = lib.mkIf config.user.dev.npm.enable {
    environment.systemPackages = [
      pkgs.nodejs
    ];
  };
}

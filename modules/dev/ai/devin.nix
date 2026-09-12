{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.dev.devin = {
    enable = lib.mkEnableOption "devin-cli package";
  };

  config = lib.mkIf config.user.dev.devin.enable {
    environment.systemPackages = [
      pkgs.devin-cli
    ];
  };
}

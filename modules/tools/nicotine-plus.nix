{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.tools.nicotine-plus = {
    enable = lib.mkEnableOption "Nicotine+ Soulseek client";
  };
  config = lib.mkIf config.user.tools.nicotine-plus.enable {
    environment.systemPackages = [
      pkgs.nicotine-plus
    ];
    networking.firewall = {
      allowedTCPPorts = [2234];
      allowedUDPPorts = [2234];
    };
  };
}

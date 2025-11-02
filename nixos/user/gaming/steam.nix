{
  config,
  pkgs,
  lib,
  ...
}: {
  config = lib.mkIf config.user.gaming.core.enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      extraCompatPackages = [pkgs.proton-ge-bin];
      package =
        pkgs.steam.override {
        };
    };

    hardware.steam-hardware.enable = true;

    # usr.files.".config/steam/steam_dev.cfg" = {
    #   text = ''
    #     unShaderBackgroundProcessingThreads ${toString cfg.shaderThreads}
    #   '';
    #   clobber = true;
    # };
  };
}

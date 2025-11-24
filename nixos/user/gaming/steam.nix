{
  config,
  pkgs,
  lib,
  ...
}: {
  options.user.gaming.steam = {
    enable = lib.mkEnableOption "Steam";
  };

  config = lib.mkIf config.user.gaming.steam.enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      extraCompatPackages = lib.optionals config.user.gaming.proton.enable [pkgs.proton-ge-bin];
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

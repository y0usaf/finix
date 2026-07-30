{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.gaming.steam = {
    enable = lib.mkEnableOption "Steam";
  };

  config = lib.mkIf config.user.gaming.steam.enable {
    programs.steam = {
      enable = true;
      # openFirewall dropped 2026-07-30: `programs` is not on compat-import's
      # whitelist, so these never reached the running finix desktop (which had
      # no filter at all — DRIFT-AUDIT #1). The steam ports they stood for
      # (TCP 27015/27036, UDP 27015 + 27031-27036) are now declared once, in
      # hosts/y0usaf-desktop/finix/firewall.nix.
      extraCompatPackages = lib.optionals config.user.gaming.proton.enable [pkgs.proton-ge-bin];
      package =
        pkgs.steam.override {
        };
    };

    hardware.steam-hardware.enable = true;

    # manzil.users."${config.user.name}".files.".config/steam/steam_dev.cfg" = {
    #   text = ''
    #     unShaderBackgroundProcessingThreads ${toString cfg.shaderThreads}
    #   '';
    #   clobber = true;
    # };
  };
}

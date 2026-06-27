{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  shojiwmPkg = flakeInputs.shojiwm.packages."${pkgs.stdenv.hostPlatform.system}".default;
in {
  config = lib.mkIf config.user.ui.shojiwm.enable {
    environment.systemPackages = [
      shojiwmPkg
      pkgs.grim
      pkgs.slurp
      pkgs.wl-clipboard-rs
      pkgs.jq
      pkgs.swaybg
    ];

    # Register the ShojiWM Wayland session (shojiwm.package exposes
    # passthru.providedSessions = ["shojiwm"]).
    services.displayManager.sessionPackages = [shojiwmPkg];

    # Wire the xdg-desktop-portal-shojiwm backend as a user systemd service.
    systemd.packages = [shojiwmPkg];
    systemd.user.services."xdg-desktop-portal-shojiwm".unitConfig = {
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };

    # Default user config: ship the default config template so the compositor
    # has something to load. Users can override this with their own tsx.
    manzil.users."${config.user.name}".files.".config/shojiwm/src/index.tsx".source = "${shojiwmPkg}/share/shojiwm/default-config/src/index.tsx";
  };
}

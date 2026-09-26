{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.user.dev.paseo.desktop;
  inherit (config.user.dev.paseo) enable;
  inherit (pkgs.stdenv.hostPlatform) system;
in {
  options.user.dev.paseo.desktop = {
    enable = lib.mkEnableOption ''
      Paseo desktop app (Electron wrapper around the Paseo web UI). Pairs with
      the Paseo daemon (user.dev.paseo.enable) on the same host; the app
      connects to the daemon's listen address.
    '';
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = enable;
        message = "user.dev.paseo.desktop.enable requires user.dev.paseo.enable (the daemon must run for the desktop app to connect to).";
      }
    ];

    environment.systemPackages = [
      flakeInputs.paseo.packages."${system}".desktop
    ];
  };
}

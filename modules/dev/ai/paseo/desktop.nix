# Paseo desktop app (user.dev.paseo.desktop).
#
# The paseo flake ships two packages: `default` (the daemon, wired as a finit
# service in service.nix) and `desktop` (paseo-desktop, an Electron wrapper
# around the same web UI). This module installs the desktop app so it can pair
# with the daemon on the same host. It is GUI-only, so it belongs on the
# desktop host (not the server), and it needs the daemon running
# (user.dev.paseo.enable) to have anything to connect to.
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
    # The desktop app is a GUI companion to the daemon; installing it without
    # the daemon would leave it with nothing to connect to.
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

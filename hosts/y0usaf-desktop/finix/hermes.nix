# Hermes Desktop (NousResearch) — Electron shell for the Hermes Agent.
#
# Thin client over the SERVER's hermes dashboard (hermes dashboard on
# y0usaf-server:9119, tailnet-only — see hosts/y0usaf-server/finix/hermes.nix
# for that service + its basic-auth secrets): the agent process, its tools
# and its shell all execute server-side; the app is a WebSocket front end.
#
# Package: flake `desktop` = full.hermesDesktop (electron wrapper around the
# complete hermes venv — NOT the `minimal` the server installs; the desktop
# build carries the optional voice/messaging SDK groups).
{
  pkgs,
  flakeInputs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
in {
  environment.systemPackages = [
    flakeInputs.hermes-agent.packages."${system}".desktop
    # niri is a Wayland compositor; same ozone shim the codex-desktop
    # module uses for its Electron apps.
    (pkgs.writeShellScriptBin "hermes-desktop-launcher" ''
      export NIXOS_OZONE_WL=1
      export ELECTRON_OZONE_PLATFORM_HINT=wayland
      exec hermes-desktop "$@"
    '')
  ];
}

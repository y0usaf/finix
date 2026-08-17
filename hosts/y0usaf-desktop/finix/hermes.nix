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
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  hermesDesktop = flakeInputs.hermes-agent.packages."${system}".desktop;
in {
  environment.systemPackages = [
    hermesDesktop
    # niri is a Wayland compositor; same ozone shim the codex-desktop
    # module uses for its Electron apps.
    (pkgs.writeShellScriptBin "hermes-desktop-launcher" ''
      export NIXOS_OZONE_WL=1
      export ELECTRON_OZONE_PLATFORM_HINT=wayland
      exec hermes-desktop "$@"
    '')
  ];

  # hermes-desktop's electron wrapper ships no .desktop file, so declare the
  # app-menu entry here — same manzil user-file pattern the webapp modules
  # use. ~/.local/share/applications is what the tui-launcher globs (and
  # what any niri app menu picks up); Exec goes through the launcher so the
  # Wayland env vars above are always applied. Icon is git-tracked inside
  # the hermes-agent flake input, so it survives store materialization.
  manzil.users."${config.user.name}".files.".local/share/applications/hermes.desktop" = {
    generator = lib.generators.toINI {};
    value."Desktop Entry" = {
      Name = "Hermes Agent";
      GenericName = "AI Agent";
      Comment = "Hermes Agent desktop shell (Nous Research)";
      Exec = "hermes-desktop-launcher %U";
      Icon = "${flakeInputs.hermes-agent}/apps/desktop/assets/icon.png";
      Terminal = "false";
      Type = "Application";
      StartupWMClass = "hermes-desktop";
      StartupNotify = "true";
      Categories = "Development;Utility;";
      Keywords = "ai;agent;assistant;nous;hermes";
    };
  };
}

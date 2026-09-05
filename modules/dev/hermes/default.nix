# Hermes runs locally as the desktop user. The app owns its backend;
# CLI and desktop share ~/.hermes, with no server or SSH workspace.
{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  hermesFull = flakeInputs.hermes-agent.packages.${system}.default;
  upstreamDesktopNix = builtins.readFile "${flakeInputs.hermes-agent}/nix/desktop.nix";
  patchedDesktopNix =
    builtins.replaceStrings
    [
      "{\n  pkgs,"
      "sha256-f8bSbLRmtbP93CJAvEBs+sHWDZ1xP2bcpLhC1EnOmZU="
      "\${../apps/desktop/assets/icon.png}"
      "\${../hermes_cli/linux_desktop_entry.py}"
    ]
    [
      "{\n  hermesSrc,\n  pkgs,"
      "sha256-CyzcARd1+GhWr8ED7HBYW2MYD+tgetqZFMkaivaGvw0="
      "\${hermesSrc}/apps/desktop/assets/icon.png"
      "\${hermesSrc}/hermes_cli/linux_desktop_entry.py"
    ]
    upstreamDesktopNix;
  hermesDesktop = assert lib.assertMsg (patchedDesktopNix != upstreamDesktopNix) "Hermes Electron headers hash patch no longer applies";
    pkgs.callPackage (pkgs.writeText "hermes-desktop.nix" patchedDesktopNix) {
      hermesSrc = flakeInputs.hermes-agent;
      inherit (hermesFull) hermesNpmLib;
      hermesAgent = hermesFull;
    };
in {
  environment.systemPackages = [
    hermesFull
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

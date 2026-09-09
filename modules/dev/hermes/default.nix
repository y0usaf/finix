# Hermes runs locally as the desktop user. The app owns its backend;
# CLI and desktop share ~/.hermes, with no server or SSH workspace.
{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (config.user.dev.hermes.packages) hermesFull hermesDesktop botsMod;
in {
  environment.systemPackages = [
    hermesFull
    hermesDesktop
    config.user.dev.hermes.projectRunner
    (pkgs.callPackage "${flakeInputs.hermes-desktop-terminal}/package.nix" {
      inherit hermesDesktop;
      hermesAgent = hermesFull;
    })
    (pkgs.writeShellScriptBin "hermes-desktop-launcher" ''
      export NIXOS_OZONE_WL=1
      export ELECTRON_OZONE_PLATFORM_HINT=wayland
      exec hermes-desktop \
        --disable-background-timer-throttling \
        --disable-backgrounding-occluded-windows \
        "$@"
    '')
  ];

  manzil.users."${config.user.name}".files = {
    ".hermes/desktop-plugins/bots-mod/plugin.js".source = "${botsMod}/plugin.js";
    ".local/share/applications/hermes.desktop" = {
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
  };
}

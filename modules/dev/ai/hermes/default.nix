# Hermes runs locally as the desktop user. The app owns its backend;
# CLI and desktop share ~/.hermes, with no server or SSH workspace.
{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (config.user.dev.ai.hermes.packages) hermesFull hermesDesktop botsMod;
  # The jev-skill-router plugin's two files: a gated, fail-open per-turn skill
  # hint. It registers only the pre_llm_call hook (no tools); its `plugins.enabled`
  # entry lives in behavior-settings.json.
  routerFiles = map (file: {
    name = ".hermes/plugins/jev-skill-router/${file}";
    value = {
      source = "${./plugins/jev-skill-router/${file}}";
      clobber = true;
    };
  }) ["__init__.py" "plugin.yaml"];
  # The cwd-command plugin's two files: an in-session `/cwd` that prints the
  # working directory the shell/file tools actually use, or retargets the session
  # (process cwd, TERMINAL_CWD, session record, and the live terminal backend).
  # Its `plugins.enabled` entry lives in behavior-settings.json.
  cwdFiles = map (file: {
    name = ".hermes/plugins/cwd-command/${file}";
    value = {
      source = "${./plugins/cwd-command/${file}}";
      clobber = true;
    };
  }) ["__init__.py" "plugin.yaml"];
  # Custom skins — one YAML per theme, theming CLI + TUI + desktop together.
  # `clobber` keeps the module authoritative over the live copy in ~/.hermes/skins/.
  skinFiles = map (file: {
    name = ".hermes/skins/${file}";
    value = {
      source = "${./skins/${file}}";
      clobber = true;
    };
  }) ["abyss.yaml"];

in {
  imports = [ ./remote-gateway.nix ];
  environment.systemPackages = [
    hermesFull
    hermesDesktop
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

  manzil.users."${config.user.name}".files =
    builtins.listToAttrs (routerFiles ++ cwdFiles ++ skinFiles)
    // {
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

  # Native remote gateway (`hermes serve`) exposed on the tailnet. This
  # directory is imported only on the desktop host; the bind address is its
  # tailnet IPv4. Credentials stay runtime-only (remote-gateway.nix).
  user.dev.ai.hermes.remoteGateway = {
    enable = true;
    listenAddress = "100.90.54.18";
  };
}

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
  # The slope-line plugin's four files. Its `line_task` tool is the delegation
  # mechanism for this profile; the `line` binary below is what it dispatches to,
  # and the two config keys that enable the plugin and disable native subagents
  # live in behavior-settings.json.
  pluginFiles = map (file: {
    name = ".hermes/plugins/slope-line/${file}";
    value = {
      source = "${./plugins/slope-line/${file}}";
      clobber = true;
    };
  }) ["__init__.py" "plugin.yaml" "schemas.py" "tools.py"];
  # Custom skins — one YAML per theme, theming CLI + TUI + desktop together.
  # `clobber` keeps the module authoritative over the live copy in ~/.hermes/skins/.
  skinFiles = map (file: {
    name = ".hermes/skins/${file}";
    value = {
      source = "${./skins/${file}}";
      clobber = true;
    };
  }) ["abyss.yaml"];
  # `line` (slope) is the process behind Hermes's `line_task` delegation and is
  # usable directly. Slope reads its own config on every run and `system`
  # replaces its built-in prompt, so restate slope's minimal operational
  # guidance verbatim (slope src/line.lisp:29-38) and append the shared
  # no-test-authoring policy.
  lineSystem = lib.concatStrings [
    "You are a non-interactive agent. You complete one task, then stop. "
    "Use the shell tool to inspect and change the working directory. Work in "
    "small, verifiable steps: look before you change, and check your work. "
    "Every shell call takes a one-line reason. Each call starts fresh in the "
    "working directory named by the tool; a cd does not persist. Finish with "
    "a short report of what you did and what you found. Do not describe what "
    "you intend to do next."
    "\n\n"
    config.user.dev.prompts.noTests
    "\n"
  ];
in {
  imports = [ ./remote-gateway.nix ];
  environment.systemPackages = [
    hermesFull
    hermesDesktop
    flakeInputs.slope.packages.${pkgs.system}.default
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
    builtins.listToAttrs (pluginFiles ++ skinFiles)
    // {
      ".hermes/desktop-plugins/bots-mod/plugin.js".source = "${botsMod}/plugin.js";
      # Native slope config for `line`. merge keeps the provider/model/key/header
      # keys the file already holds and only sets `system`.
      ".config/slope/config.json" = {
        type = "merge";
        format = "json";
        clobber = true;
        value.system = lineSystem;
      };
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

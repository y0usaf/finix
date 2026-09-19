# Hermes runtime and desktop builders. The caller owns upstream pins and policy.
{
  lib,
  pkgs,
  hermesSource ? throw "hermesSource is required",
  botsSource ? throw "botsSource is required",
  apiKeyFile ? throw "apiKeyFile is required",
  ...
}@args:
# Every `modules/**/*.nix` path is imported as a NixOS module. This file is a
# `pkgs.callPackage` builder: the module system always passes `config`, so
# contribute nothing there, while `pkgs.callPackage` omits `config` and gets the
# built packages.
if args ? config
then {}
else let
  inherit (pkgs.stdenv.hostPlatform) system;
  botsMod = pkgs.runCommand "hermes-bots-mod" {} ''
    mkdir -p $out
    # The pinned fork includes internal-chat visibility, the compact bot shelf,
    # no unsolicited greetings, and archive-next navigation.
    cp ${botsSource}/plugin.js $out/plugin.js
    ${pkgs.nodejs}/bin/node --check "$out/plugin.js"
    ${pkgs.nodejs}/bin/node ${botsSource}/roster.test.mjs "$out/plugin.js"
    ${pkgs.nodejs}/bin/node ${botsSource}/shelf.test.mjs "$out/plugin.js"
    cp ${botsSource}/LICENSE $out/LICENSE
  '';
  hermesUpstream = hermesSource.packages.${system}.default;
  # Stock upstream Hermes, plus two install-only wrappers: the `_HERMES_GATEWAY`
  # unwrap for CLI children and the runtime credential loader. No source patch.
  hermesFull = hermesUpstream.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [pkgs.makeWrapper];
    postFixup =
      (old.postFixup or "")
      + ''
        # This marker belongs to the gateway PROCESS, not CLI children it
        # launches. Inheriting it makes --in keep the parent's TERMINAL_CWD.
        # Actual gateways set their own marker during gateway initialization.
        wrapProgram "$out/bin/hermes" \
          --unset _HERMES_GATEWAY \
          --set-default HERMES_API_KEY_FILE ${lib.escapeShellArg apiKeyFile} \
          --run ${lib.escapeShellArg "source ${./load-credentials.sh}"}
        ${hermesUpstream.hermesVenv}/bin/python3 ${./test_cli_child_cwd.py} "$out/bin/hermes"
      '';
  });

  # The desktop is a TOP-LEVEL user app, not a descendant of whoever launched
  # it. Launched from an agent shell it would otherwise inherit that process's
  # markers, and the board still READS while every mutation fails closed:
  #   kanban_db._assert_not_delegated_child_mutation
  #   PermissionError: delegate_task child contexts cannot mutate Kanban tasks
  # (the UI swallows it -- `Create task` is a silent no-op). An inherited
  # HERMES_KANBAN_DB/HERMES_KANBAN_BOARD is worse: it silently pins the app to
  # the launcher's board instead of the `current` one. Scrub them in the
  # wrapper so the app's whole process tree (its spawned backend included)
  # looks exactly like a menu launch.
  desktopEnvScrub = [
    "HERMES_DELEGATED_CHILD_CONTEXT"
    "HERMES_KANBAN_TASK"
    "HERMES_KANBAN_RUN_ID"
    "HERMES_KANBAN_CLAIM_LOCK"
    "HERMES_KANBAN_GOAL_MODE"
    "HERMES_KANBAN_GOAL_MAX_TURNS"
    "HERMES_KANBAN_DB"
    "HERMES_KANBAN_BOARD"
    "HERMES_KANBAN_HOME"
    "HERMES_KANBAN_WORKSPACE"
    "HERMES_KANBAN_WORKSPACES_ROOT"
    "HERMES_KANBAN_ATTACHMENTS_ROOT"
  ];
  desktopEnvScrubFlags = lib.concatMapStrings (name: "--unset ${name} ") desktopEnvScrub;

  # Upstream `nix/desktop.nix` is written to the store, so its relative asset
  # paths no longer resolve and its electron-headers sha256 is pinned to the
  # upstream nixpkgs electron (41.x). We build against finix's nixpkgs (electron
  # 43.4.1), so rewrite both: a `hermesSrc` arg + absolute asset/entry paths, and
  # the matching electron 43.4.1 headers sha256. Install needs only -- the Hermes
  # desktop source itself is unmodified.
  upstreamDesktopNix = builtins.readFile "${hermesSource}/nix/desktop.nix";
  desktopNix =
    builtins.replaceStrings
    ["{\n  pkgs," "sha256-f8bSbLRmtbP93CJAvEBs+sHWDZ1xP2bcpLhC1EnOmZU=" "\${../apps/desktop/assets/icon.png}" "\${../hermes_cli/linux_desktop_entry.py}"]
    ["{\n  hermesSrc,\n  pkgs," "sha256-CyzcARd1+GhWr8ED7HBYW2MYD+tgetqZFMkaivaGvw0=" "\${hermesSrc}/apps/desktop/assets/icon.png" "\${hermesSrc}/hermes_cli/linux_desktop_entry.py"]
    upstreamDesktopNix;
  hermesDesktop =
    (pkgs.callPackage (pkgs.writeText "hermes-desktop.nix" desktopNix) {
      hermesSrc = hermesSource;
      inherit (hermesUpstream) hermesNpmLib;
      hermesAgent = hermesFull;
    }).overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or []) ++ [pkgs.makeWrapper];
      postFixup =
        (old.postFixup or "")
        + ''
          wrapProgram "$out/bin/hermes-desktop" \
            ${desktopEnvScrubFlags}\
            --set-default HERMES_API_KEY_FILE ${lib.escapeShellArg apiKeyFile} \
            --run ${lib.escapeShellArg "source ${./load-credentials.sh}"}
        '';
    });
in {inherit hermesFull hermesDesktop botsMod;}

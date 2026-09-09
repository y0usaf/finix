{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  botsMod = pkgs.runCommand "hermes-bots-mod" {} ''
    mkdir -p $out
    # The pinned fork includes internal-chat visibility, the compact bot shelf,
    # no unsolicited greetings, and archive-next navigation.
    cp ${flakeInputs.hermes-bots-mod}/plugin.js $out/plugin.js
    ${pkgs.nodejs}/bin/node --check "$out/plugin.js"
    ${pkgs.nodejs}/bin/node ${flakeInputs.hermes-bots-mod}/roster.test.mjs "$out/plugin.js"
    ${pkgs.nodejs}/bin/node ${flakeInputs.hermes-bots-mod}/shelf.test.mjs "$out/plugin.js"
    check_root="$TMPDIR/archive-check"
    action_path="apps/desktop/src/app/session/hooks/use-session-actions/index.ts"
    mkdir -p "$check_root/$(dirname "$action_path")"
    cp ${flakeInputs.hermes-agent}/apps/desktop/src/app/session/hooks/use-session-actions/index.ts "$check_root/$action_path"
    chmod u+w "$check_root/$action_path"
    ${pkgs.patch}/bin/patch --batch --forward --fuzz=0 -p1 -d "$check_root" < ${./patches/desktop-archive-next.patch}
    ${pkgs.nodejs}/bin/node ${./test_archive_next.mjs} "$out/plugin.js" "$check_root/$action_path"
    cp ${flakeInputs.hermes-bots-mod}/LICENSE $out/LICENSE

  '';
  hermesUpstream = flakeInputs.hermes-agent.packages.${system}.default;
  patchedHermesVenv = hermesUpstream.hermesVenv.overrideAttrs (old: {
    postInstall =
      (old.postInstall or "")
      + ''
        gateway_dir=$(find "$out/lib" -path '*/site-packages/tui_gateway' -print -quit)
        test -n "$gateway_dir"
        test -L "$gateway_dir"
        cp -rL "$gateway_dir" "$TMPDIR/patched-tui-gateway"
        chmod -R u+w "$TMPDIR/patched-tui-gateway"
        unlink "$gateway_dir"
        mv "$TMPDIR/patched-tui-gateway" "$gateway_dir"
        site_packages=$(dirname "$gateway_dir")
        ${pkgs.patch}/bin/patch --batch --forward --fuzz=0 -p1 -d "$site_packages" < ${./patches/session-metadata.patch}
      '';
  });
  hermesFull = hermesUpstream.overrideAttrs (old: {
    installPhase = assert lib.hasInfix (builtins.unsafeDiscardStringContext "${hermesUpstream.hermesVenv}") old.installPhase;
      builtins.replaceStrings ["${hermesUpstream.hermesVenv}"] ["${patchedHermesVenv}"] old.installPhase;
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [pkgs.makeWrapper];
    postFixup =
      (old.postFixup or "")
      + ''
        # This marker belongs to the gateway PROCESS, not CLI children it
        # launches. Inheriting it makes --in keep the parent's TERMINAL_CWD.
        # Actual gateways set their own marker during gateway initialization.
        wrapProgram "$out/bin/hermes" \
          --unset _HERMES_GATEWAY \
          --set-default HERMES_API_KEY_FILE ${lib.escapeShellArg config.user.dev.hermes.apiKeyFile} \
          --run ${lib.escapeShellArg "source ${./load-credentials.sh}"}
        ${patchedHermesVenv}/bin/python3 ${./test_cli_child_cwd.py} "$out/bin/hermes"
      '';
    passthru = (old.passthru or {}) // {hermesVenv = patchedHermesVenv;};
  });

  managedNpmLib =
    hermesFull.hermesNpmLib
    // {
      buildNpmPackage = args:
        (hermesFull.hermesNpmLib.buildNpmPackage args).overrideAttrs (old: {
          preBuild =
            (old.preBuild or "")
            + ''
              ${pkgs.patch}/bin/patch --batch --forward --fuzz=0 -p1 < ${./patches/plugin-policy.patch}
              ${pkgs.patch}/bin/patch --batch --forward --fuzz=0 -p1 < ${./patches/data-poll-visible-unfocused.patch}
              ${pkgs.patch}/bin/patch --batch --forward --fuzz=0 -p1 < ${./patches/desktop-archive-next.patch}
            '';
        });
    };
  upstreamDesktopNix = builtins.readFile "${flakeInputs.hermes-agent}/nix/desktop.nix";
  patchedDesktopNix =
    builtins.replaceStrings
    ["{\n  pkgs," "sha256-f8bSbLRmtbP93CJAvEBs+sHWDZ1xP2bcpLhC1EnOmZU=" "\${../apps/desktop/assets/icon.png}" "\${../hermes_cli/linux_desktop_entry.py}"]
    ["{\n  hermesSrc,\n  pkgs," "sha256-CyzcARd1+GhWr8ED7HBYW2MYD+tgetqZFMkaivaGvw0=" "\${hermesSrc}/apps/desktop/assets/icon.png" "\${hermesSrc}/hermes_cli/linux_desktop_entry.py"]
    upstreamDesktopNix;
  hermesDesktop =
    (pkgs.callPackage (pkgs.writeText "hermes-desktop.nix" patchedDesktopNix) {
      hermesSrc = flakeInputs.hermes-agent;
      hermesNpmLib = managedNpmLib;
      hermesAgent = hermesFull;
    }).overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or []) ++ [pkgs.makeWrapper];
      postFixup =
        (old.postFixup or "")
        + ''
          wrapProgram "$out/bin/hermes-desktop" \
            --set-default HERMES_API_KEY_FILE ${lib.escapeShellArg config.user.dev.hermes.apiKeyFile} \
            --run ${lib.escapeShellArg "source ${./load-credentials.sh}"}
        '';
    });
in {
  options.user.dev.hermes.packages = lib.mkOption {
    type = lib.types.attrsOf lib.types.package;
    description = "Hermes runtime, desktop and Bots Mod UI.";
    default = {inherit hermesFull hermesDesktop botsMod;};
  };
}

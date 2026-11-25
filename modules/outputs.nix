inputs: let
  system = "x86_64-linux";
  inherit (pkgs) lib;
  packagesFor = platform: builtins.mapAttrs (_: input: input.packages.${platform} or {}) inputs;
  rawInputPackages = packagesFor system;
  ompBuild = rawInputPackages.oh-my-pi.omp.overrideAttrs (old: {
    patches =
      (old.patches or [])
      ++ [
        ./dev/ai/omp/advisor-bounded-replay.patch
        ./dev/ai/omp/date-cwd-append-only.patch
        ./dev/ai/omp/lazy-restore-scan.patch
        ./dev/ai/omp/clipboard-paste-deadline.patch
        ./dev/ai/omp/composer-cost-brief.patch
        ./dev/ai/omp/eval-internal-read-no-inline.patch
        ./dev/ai/omp/agy-roster-rotation.patch
        ./dev/ai/omp/agy-notice-fallback.patch
        ./dev/ai/omp/antigravity-neon-roster.patch
        ./dev/ai/omp/prompt-ablate-guards.patch
        ./dev/ai/omp/instant-send.patch
        ./dev/ai/omp/fallback-fit-provider-usage.patch
        ./dev/ai/omp/message-helper.patch
        ./dev/ai/omp/advisor-not-primary.patch
        ./dev/ai/omp/refusal-fallback.patch
        ./dev/ai/omp/agy-session-idle-reap.patch
        ./dev/ai/omp/agy-warm-cancel.patch
        ./dev/ai/omp/helper-compaction.patch
        ./dev/ai/omp/eval-only-nested-tools.patch
        ./dev/ai/omp/mcp-reliability.patch
        ./dev/ai/omp/agy-checkpoint-and-replay-budget.patch
      ];
    postPatch =
      (old.postPatch or "")
      + ''
        substituteInPlace packages/coding-agent/scripts/compile-binary.ts --replace-fail 'chunks/[name]-[hash].[ext]' 'chunks/[dir]/[name]-[hash].[ext]'
        prompts=packages/coding-agent/src/prompts
        for f in \
          advisor/active-repo-watchdog.md \
          advisor/boundary-guidance.md \
          advisor/memory-context.md \
          advisor/system.md \
          agents/task.md \
          system/browser-user-session.md \
          system/browser-x11.md \
          system/computer-use.md \
          system/system-prompt.md \
          tools/commit-guidance.md \
          tools/dsm-guidance.md; do
          test -f "$prompts/$f"
          : > "$prompts/$f"
        done
        for f in \
          advisor/context-files.md \
          system/project-prompt.md \
          system/subagent-system-prompt.md \
          tools/ask.md \
          tools/bash.md \
          tools/browser-core.md \
          tools/eval.md \
          tools/task-async-contract.md \
          tools/task.md \
          tools/write.md; do
          test -f "$prompts/$f"
        done
        for f in advisor/context-files.md system/project-prompt.md; do
          cat > "$prompts/$f" <<'EOF'
        {{#each contextFiles}}
        {{content}}

        {{/each}}
        EOF
        done
        grep -q 'agent: inputs.agentSystemPrompt' packages/coding-agent/src/task/executor.ts
        cat > "$prompts/system/subagent-system-prompt.md" <<'EOF'
        {{#if agent}}{{agent}}

        {{/if}}{{#if context}}{{context}}{{/if}}{{#if outputSchema}}
        {{renderYieldSchema outputSchema}}{{/if}}
        EOF
        cat > "$prompts/tools/ask.md" <<'EOF'
        Show the user one semantic HTML `<form>` (blocks until Submit/Cancel). No `<script>`, `<style>`, `style=`, or `<button>`/`type="submit"` (UI adds Submit/Cancel). Every control needs `name`; returns JSON `{"name": value}`. Wrap controls in `<label>`, group in `<fieldset><legend>`. Radio/checkbox groups auto-get "Other" (don't add one). Preselect recommendation with `checked`/`selected`/`value`.
        EOF
        cat > "$prompts/tools/bash.md" <<'EOF'
        Run a bash command (`cwd` resets per call; `pty` for interactive programs; internal URIs work as paths; long output spills to `artifact://`).
        {{#if asyncEnabled}}`async`: returns immediately, delivers result later (deadline {{defaultTimeoutSec}}s; `timeout: 0` disables).{{/if}}
        {{#if hasLaunch}}Long-lived service: set `name` + `ready` (`log` regex and/or `port`).{{/if}}
        {{#if autoBackgroundEnabled}}Calls >{{autoBackgroundSeconds}}s move to `bg_N` and deliver later; don't poll.{{/if}}
        EOF
        cat > "$prompts/tools/eval.md" <<'EOF'
        Persistent {{#if py}}Python{{/if}}{{#ifAll py js}}/{{/ifAll}}{{#if js}}JS{{/if}} cell (subagents have separate kernels; top-level `await` works).
        {{#if py}}Builtins: `print`, `log`, `phase`, `env`, `read(path, offset?, limit?)`, `write(path, content)`, `output(*ids, format?, query?, offset?, limit?)`, `wait(handles, timeout?, raise_errors?)`, `sh(cmd, cwd?, timeout?)` (raises `ShellError`).{{/if}}
        {{#if js}}Builtins: `print`, `log`, `phase`, `env`, `read`, `write`, `output`, `wait`, `sh`.{{/if}}
        {{#if nestedTools}}Tools (`await tool.<name>(**kwargs)`; `tool.help(name?)`, `tool.schema(name)`): {{#each nestedTools}}`{{name}}`{{#unless @last}}, {{/unless}}{{/each}}.{{else}}{{#if toolNames}}Tools (`await tool.<name>(**kwargs)`): {{#each toolNames}}`{{this}}`{{#unless @last}}, {{/unless}}{{/each}}.{{/if}}{{/if}}
        {{#if autoBackgroundEnabled}}Long cells move to background and deliver later.{{/if}}
        EOF
        cat > "$prompts/tools/task-async-contract.md" <<'EOF'
        IDs return immediately; results arrive as follow-up messages. Never poll.
        EOF
        cat > "$prompts/tools/task.md" <<'EOF'
        Spawn subagents in `tasks[]` in parallel (IDs return immediately; results arrive later; never poll). Helpers start blank: put shared background in `context` and per-helper goal/files/limits/done-check in `task`.
        - `agent`: omit for `{{defaultAgent}}`. `name`: CamelCase ≤32 chars. `solutionSpace`: openness hint.
        {{#if evalToolsEnabled}}- `tools`: eval-defined tools (run in your kernel).{{/if}}
        {{#if perCallModelEnabled}}- `model`: exact `provider/model-id` from {{#if perCallModelAdvertisement.allowlist.length}}{{#list perCallModelAdvertisement.allowlist join=", "}}`{{this}}`{{/list}}{{else}}configured models{{/if}}{{#unless perCallModelAdvertisement.parentModelWithheld}} or own model{{/unless}}.{{/if}}
        Agents:
        {{#list agents join=""}}- `{{name}}`: {{description}}
        {{/list}}
        EOF
        cat > "$prompts/tools/write.md" <<'EOF'
        Create or overwrite a file (`archive.ext:member` writes into ZIP/tar/.asar; `db.sqlite:table[:key]` inserts/updates, empty deletes).
        EOF
        ${pkgs.python3}/bin/python3 - "$prompts/tools/browser-core.md" <<'PY'
        import sys
        p = sys.argv[1]
        s = open(p).read()
        marker = "<instruction>\n"
        line = "- Real user sessions: never navigate a borrowed `target` tab without permission, and never fake page steps with scripts.\n"
        assert marker in s, "browser-core.md marker not found"
        open(p, "w").write(s.replace(marker, marker + line, 1))
        PY
      '';
  });
  ompMessageHelperE2e = let
    marker = ''echo "Compiling OMP"'';
    parts = lib.splitString marker ompBuild.buildPhase;
  in
    assert lib.length parts == 2;
      ompBuild.overrideAttrs {
        pname = "omp-message-helper-e2e";
        buildPhase =
          lib.head parts
          + ''
            cp ${./dev/ai/omp/message-helper.ts} packages/coding-agent/test/finix-message-helper.ts
            cp ${./dev/ai/omp/message-helper.e2e.ts} packages/coding-agent/test/finix-message-helper.e2e.test.ts
            export HOME="$TMPDIR/home"
            mkdir -p "$HOME"
            bun --cwd="$PWD/packages/coding-agent" test test/finix-message-helper.e2e.test.ts
            runHook postBuild
          '';
        installPhase = ''
          touch $out
        '';
        dontFixup = true;
        doInstallCheck = false;
        disallowedReferences = [];
      };
  omp = pkgs.symlinkJoin {
    name = "omp-${ompBuild.version}";
    inherit (ompBuild) version;
    paths = [ompBuild];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/omp \
        --set-default PI_AGY_PATH ${import ../pkgs/agy.nix {inherit pkgs;}}/bin/agy \
        --suffix PATH : ${lib.makeBinPath [pkgs.netcat]}
    '';
  };
  piDonsetch = pkgs.runCommand "pi-donsetch-trimmed" {} ''
        cp -r ${rawInputPackages.pi-donsetch.default} $out
        chmod -R u+w $out
        ${pkgs.python3}/bin/python3 - "$out/pi-extension.ts" <<'EOF'
    import sys
    p = sys.argv[1]
    s = open(p).read()
    old = """      const description = mcpTool.description || mcpTool.name;
          const inputSchema = mcpTool.inputSchema || { type: "object", properties: {} };"""
    new = r"""      const firstLine = (t: unknown, max = 140) => {
            const line = String(t ?? "").split(/\r?\n/)[0].split(". ")[0].trim();
            return line.length > max ? line.slice(0, max - 1) + "…" : line;
          };
          const description = firstLine(mcpTool.description || mcpTool.name, 140);
          const rawSchema = mcpTool.inputSchema || { type: "object", properties: {} };
          const inputSchema = rawSchema.properties
            ? { ...rawSchema, properties: Object.fromEntries(Object.entries(rawSchema.properties).map(([k, v]: [string, any]) => [k, v && typeof v === "object" && v.description ? { ...v, description: firstLine(v.description, 80) } : v])) }
            : rawSchema;"""
    assert old in s, "pi-extension.ts pattern not found"
    open(p, "w").write(s.replace(old, new, 1))
    EOF
  '';
  inputPackages =
    rawInputPackages
    // {
      oh-my-pi = rawInputPackages.oh-my-pi // {inherit omp;};
      pi-donsetch = rawInputPackages.pi-donsetch // {default = piDonsetch;};
    };

  mkPkgs = cudaSupport:
    import (toString inputs.nixpkgs) {
      inherit system;
      config = {
        allowUnfree = true;
        inherit cudaSupport;
      };
      overlays = [
        inputs.claude-code-nix.overlays.default
        (_: _: {
          rush = inputPackages.rush.default.overrideAttrs (old: {
            patches = (old.patches or []) ++ [./shell/rush-login-command.patch];
          });
          monstar = inputPackages.monstar.default;
          ash = inputPackages.ash.default;
        })
        (_: prev: {
          tectonic-unwrapped = prev.tectonic-unwrapped.overrideAttrs (old: {
            buildInputs = (old.buildInputs or []) ++ [prev.aws-lc];
          });
          egl-wayland2 = prev.egl-wayland2.overrideAttrs (old: {
            patches = (old.patches or []) ++ [./core/egl-wayland2-feedback-double-free.patch];
          });
          obs-studio-plugins =
            prev.obs-studio-plugins
            // {
              obs-vertical-canvas = prev.obs-studio-plugins.obs-vertical-canvas.overrideAttrs (old: {
                postPatch =
                  (old.postPatch or "")
                  + ''
                    sed -i '/find_qt(COMPONENTS Widgets COMPONENTS_LINUX Gui)/a find_package(Qt6 REQUIRED COMPONENTS GuiPrivate)' CMakeLists.txt
                  '';
              });
            };
        })
      ];
    };
  pkgs = mkPkgs false;

  mkFinixSystem = {
    modules,
    cudaSupport ? false,
  }:
    inputs.finix.lib.finixSystem {
      inherit lib;
      specialArgs = {
        flakeInputs = inputs;
        generators = inputs.nix-generators.lib;
        inherit inputPackages;
      };
      modules =
        [
          {
            nixpkgs.pkgs =
              if cudaSupport
              then mkPkgs true
              else pkgs;
          }
          inputs.finix.nixosModules.bash
          inputs.finix.nixosModules.chronyd
          inputs.finix.nixosModules.dhcpcd
          inputs.finix.nixosModules.getty
          inputs.finix.nixosModules.openssh
          ./finix/sudo.nix
          inputs.finix.nixosModules.sysklogd
          ./finix/chrony.nix
          ./finix/common.nix
          ./finix/emudhra-distrust.nix
          ./finix/persist-order.nix
          ./finix/persistence.nix
        ]
        ++ modules;
    };

  nixFiles = dirs: builtins.filter (f: lib.hasSuffix ".nix" (toString f)) (builtins.concatMap lib.filesystem.listFilesRecursive dirs);
  graphicalModules = nixFiles [
    ./core
    ./desktop
    ./dev
    ./gaming
    ./shell
    ./tools
    ./user-services
    ./hosts/common
  ];

  baseModules = [
    inputs.finix.nixosModules.nix-daemon
    inputs.finix.nixosModules.nftables
    ./finix/diagnostics.nix
    inputs.manzil.finixModules.default
  ];

  hosts = {
    y0usaf-server = mkFinixSystem {
      modules =
        baseModules
        ++ [
          inputs.finix.nixosModules.cron
          inputs.finix.nixosModules.postgresql
          ./server/forgejo.nix
          ./server/mediamtx.nix
          ./server/syncthing.nix
          ./hosts/y0usaf-server/config.nix
          ./finix/tailscale.nix
          ./finix/static-net.nix
          ./hosts/wireguard.nix
          ./hosts/y0usaf-server/hardware-config.nix
          ./hosts/y0usaf-server/boot.nix
          ./server/attic.nix
          ./server/packages.nix
          ./dev/ai/prompts/policy.nix
          ./dev/ai/claude-code.nix
          ./dev/ai/paseo.nix
          ./tools/git.nix
          ./tools/tern
          ./tools/tmux.nix
        ];
    };

    y0usaf-desktop = mkFinixSystem {
      cudaSupport = true;
      modules =
        baseModules
        ++ [
          inputs.finix.nixosModules.cron
          inputs.finix.nixosModules.networkmanager
          inputs.finix.nixosModules.limine
          ./finix/static-net.nix
          ./hosts/wireguard.nix
          ./dev/ai/tomoe-land.nix
        ]
        ++ graphicalModules
        ++ [
          ./finix/bootvine.nix
          {finix.bootScreen.enable = true;}
        ]
        ++ nixFiles [./hosts/y0usaf-desktop];
    };

    y0usaf-framework = mkFinixSystem {
      modules =
        baseModules
        ++ [
          inputs.finix.nixosModules.brightnessctl
          inputs.finix.nixosModules.docker
          inputs.finix.nixosModules.fwupd
          inputs.finix.nixosModules.networkmanager
          inputs.finix.nixosModules.power-profiles-daemon
          inputs.finix.nixosModules.zzz
        ]
        ++ graphicalModules
        ++ nixFiles [./hosts/y0usaf-framework];
    };
  };

  mkDeploy = {
    defaultHost,
    name,
    toplevel,
    sshHost ? null,
    sshPort ? null,
  }: let
    portStr = lib.optionalString (sshPort != null) (toString sshPort);
  in
    pkgs.writeShellScriptBin name ''
      set -euo pipefail

      host="''${1:-${defaultHost}}"
      action="''${2:-test}"
      case "$host" in
        *[!A-Za-z0-9_.:@-]*)
          echo "invalid host: $host" >&2
          exit 2
          ;;
      esac
      case "$action" in
        test|boot|switch) ;;
        *)
          echo "usage: ${name} [host] [test|boot|switch]" >&2
          exit 2
          ;;
      esac
      system_path='${toplevel}'
      remote_host="${
        if sshHost == null
        then "$host"
        else sshHost
      }"

      if [ "$host" != local ] && [ -n '${portStr}' ]; then
        export NIX_SSHOPTS='-p ${portStr} -o ControlPath=none'
        ssh_cmd=(ssh -p '${portStr}' -o ControlPath=none)
      else
        ssh_cmd=(ssh)
      fi

      if [ "$host" = local ]; then
        if [ -d /run/systemd/system ]; then
          echo "${name}: refusing local $action under systemd; target a live Finix host over ssh" >&2
          exit 1
        fi
        sudo "$system_path/sw/bin/nix-store" --realise "$system_path" \
          --add-root /nix/var/nix/gcroots/finix-persistent >/dev/null
        if [ "$action" != test ]; then
          sudo "$system_path/sw/bin/nix-env" -p /nix/var/nix/profiles/system --set "$system_path"
        fi
        sudo "$system_path/bin/switch-to-configuration" "$action"
        exit 0
      fi

      remote_store="ssh://$remote_host${lib.optionalString (sshPort != null) ":${toString sshPort}"}?remote-program=/run/current-system/sw/bin/nix-store"

      echo "==> copying persistent finix closure to $remote_host"
      nix copy --to "$remote_store" "$system_path"

      echo "==> rooting persistent closure"
      "''${ssh_cmd[@]}" "$remote_host" \
        "/run/wrappers/bin/sudo '$system_path/sw/bin/nix-store' --realise '$system_path' --add-root /nix/var/nix/gcroots/finix-persistent"

      if [ "$action" != test ]; then
        echo "==> registering system profile generation"
        "''${ssh_cmd[@]}" "$remote_host" \
          "/run/wrappers/bin/sudo /run/current-system/sw/bin/nix-env -p /nix/var/nix/profiles/system --set '$system_path'"
      fi

      echo "==> finix switch-to-configuration $action"
      "''${ssh_cmd[@]}" "$remote_host" \
        "/run/wrappers/bin/sudo '$system_path/bin/switch-to-configuration' '$action'"
      if [ "$action" != test ]; then
        "''${ssh_cmd[@]}" "$remote_host" \
          "/run/wrappers/bin/sudo /run/current-system/sw/bin/sync"
      fi
    '';

  droid = inputs."nix-on-droid".lib.nixOnDroidConfiguration {
    pkgs = import (toString inputs.nixpkgs) {
      system = "aarch64-linux";
    };
    extraSpecialArgs = {
      flakeInputs = inputs;
      generators = inputs.nix-generators.lib;
      inputPackages = packagesFor "aarch64-linux";
    };
    modules = [./hosts/android-phone/nix-on-droid.nix];
  };

  lint = import ./lint.nix {inherit inputs inputPackages lib pkgs hosts droid;};
in {
  nixosConfigurations = hosts // {y0usaf-server-finix = hosts.y0usaf-server;};

  nixOnDroidConfigurations.default = droid;

  nixosModules.steam-frame = ./hosts/steam-frame/config.nix;

  finixConfigurations = hosts;

  apps.${system}.lint = {
    type = "app";
    program = lib.getExe lint.app;
  };

  packages.${system} = {
    finix-server-persistent-deploy = mkDeploy {
      name = "finix-server-persistent-deploy";
      toplevel = hosts.y0usaf-server.config.system.topLevel;
      defaultHost = "server";
      sshHost = hosts.y0usaf-server.config.networking.hostName;
      sshPort = builtins.head hosts.y0usaf-server.config.services.openssh.settings.Port;
    };
    finix-desktop-deploy = mkDeploy {
      name = "finix-desktop-deploy";
      toplevel = hosts.y0usaf-desktop.config.system.topLevel;
      defaultHost = "local";
    };
    finix-frame-deploy = import ./hosts/steam-frame/deploy.nix {inherit inputs pkgs;};
    drift = import ./drift.nix {inherit lib pkgs hosts;};
    inherit (hosts.y0usaf-desktop.config.system.build) p4g-setup;
    omp-box-selftest = hosts.y0usaf-desktop.config.system.build.ompBoxSelftest;
    boot-screen-vm = import ./finix/bootvine-vm.nix {inherit inputs pkgs lib;};
    inherit omp;
    tomoe = inputPackages.tomoe.default;
    tomoe-stable = hosts.y0usaf-desktop.config.system.build.tomoeStable;
    glsl-gate = lint.glslGate;
  };

  checks.${system} =
    lib.mapAttrs' (name: host: lib.nameValuePair name host.config.system.build.toplevel) hosts
    // {
      strictix = lint.check;
      omp-message-helper-e2e = ompMessageHelperE2e;
    };

  formatter.${system} = inputPackages.alejandra.default;
}

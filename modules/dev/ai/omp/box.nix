{
  config,
  lib,
  pkgs,
  flakeInputs,
  inputPackages,
  generators,
  ...
}: let
  user = config.user.name;
  home = config.users.users.${user}.home;
  catalog = config.user.dev.modelCatalog;
  ablit = import ./ablit.data.nix;
  shares = [];
  json = lib.generators.toJSON {};

  proxy = pkgs.writers.writePython3Bin "omp-gateway-proxy" {} (generators.python.render (import ../../../../omp-box/gateway-proxy.data.nix generators.python));
  gatewayUrl = "http://10.0.2.2:8899";
  # What omp in the box loads: built here, and copied while the box runs by omp-box-seed into the box's seed
  # share instead of baked into the guest, so a new extension, omp-bot or prompt reaches the box without
  # restarting it and every bot in it. A generation holds the omp config files, store/ with a copy of each
  # store path below and ext/NAME, a link to its copy; the box's omp config names extensions by
  # ${seedMount}/current/ext/NAME, a path no switch changes, so a running omp sees the same extensions list.
  seedMount = "/mnt/seed";
  extensions = {
    "compact-eval.ts" = generators.sourceFile "compact-eval.ts" (generators.ts.render (import ./compact-eval.data.nix generators.ts));
    "work-fold.ts" = generators.sourceFile "work-fold.ts" (generators.ts.render (import ./work-fold.data.nix generators.ts));
    optchat = generators.sourceDir pkgs "optchat" (import ./optchat/optchat.data.nix {inherit generators;});
    inherit (flakeInputs) omp-bot;
    # The same store path as the host's ext link, so omp-bot-box names a boxed bot's secrets extension by this link.
    secrets = generators.sourceDir pkgs "secrets" (import ./secrets.data.nix);
  };
  inBox = name: "${seedMount}/current/ext/${name}";
  # Programs a boxed bot gets on PATH (box.env's OMP_BOT_BOX_PATH): the secrets extension's age and omp-secret.
  # age is linked against the guest's own glibc, which the guest always has, as it is built from the same pkgs.
  seedBin = {
    age = "${pkgs.age}/bin/age";
    age-keygen = "${pkgs.age}/bin/age-keygen";
    omp-secret = pkgs.writeScript "omp-secret" ''
      #!/bin/sh
      exec bun "''${0%/*}/../ext/secrets/omp-secret.ts" "$@"
    '';
  };
  files = {
    models = pkgs.writeText "models.json" (json catalog.models);
    modelKeys = pkgs.writeText "models.yml" ''
      providers:
        vercel-ai-gateway:
          baseUrl: ${gatewayUrl}
          apiKey: "!echo unused"
        anthropic:
          baseUrl: ${gatewayUrl}/anthropic
          apiKey: "!echo sk-ant-oat-crest"
        openai-codex:
          baseUrl: ${gatewayUrl}/openai-codex
          apiKey: "!echo crest"
        ablit:
          baseUrl: http://10.0.2.2:${toString ablit.port}/v1
          apiKey: "!echo unused"
          models:
            - api: openai-completions
              id: ${ablit.id}
              name: ${ablit.name}
              reasoning: true
              input: [text]
              contextWindow: ${toString ablit.contextWindow}
              maxTokens: ${toString ablit.maxTokens}
    '';
    # omp-ablit's own overlay (ablit.nix): a local session asks no cloud model for a review.
    ablitConfig = pkgs.writeText "ablit.yml" ''
      advisor:
        enabled: false
    '';
    settings = pkgs.writeText "settings.json" (json {
      inherit (catalog) defaultProvider defaultModel;
      defaultThinkingLevel = catalog.ompThinkingLevel;
      enabledModels = catalog.enabledModels ++ ["ablit/${ablit.id}"];
      packages = [];
    });
    config = pkgs.writeText "config.yml" ''
      setupVersion: 2
      startup:
        setupWizard: false
        checkUpdate: false
      defaultThinkingLevel: ${catalog.ompThinkingLevel}
      modelRoles:
        advisor: ${catalog.advisorModel}
        default: ${catalog.defaultProvider}/${catalog.defaultModel}
        smol: ${catalog.smolModel}
        judge: ${catalog.judgeModel}
        task: ${catalog.taskModel}
      advisor:
        enabled: true
        reviewMode: agent-end
      retry:
        fallbackChains: ${builtins.toJSON catalog.fallbackChains}
      # A steer backgrounds a running cell so a message lands at once; the hour
      # keeps omp from backgrounding long cells on its own.
      eval:
        autoBackground:
          enabled: true
          thresholdMs: 3600000
      extensions:
        - "${inBox "omp-bot"}/omp/code-mode.ts"
        - "${inBox "omp-bot"}/omp/barge-in.ts"
        - "${inBox "compact-eval.ts"}"
        - "${inBox "work-fold.ts"}"
        - "${inBox "optchat"}/extension.ts"
        - "${inBox "omp-bot"}/omp/ompd.ts"
    '';
    appendSystem = pkgs.writeText "APPEND_SYSTEM.md" "${config.user.dev.prompts.portable}\n\n${catalog.taskNote}\n";
  };
  seed = pkgs.runCommand "omp-box-seed" {} ''
    mkdir -p $out/store $out/ext $out/bin
    cp ${files.models} $out/models.json
    cp ${files.modelKeys} $out/models.yml
    cp ${files.settings} $out/settings.json
    cp ${files.config} $out/config.yml
    cp ${files.appendSystem} $out/APPEND_SYSTEM.md
    cp ${files.ablitConfig} $out/ablit.yml
    ${lib.concatStrings (lib.mapAttrsToList (name: path: let
        copy = builtins.baseNameOf (toString path);
      in ''
        cp -rL ${path} $out/store/${copy}
        ln -s ../store/${copy} $out/ext/${name}
      '')
      extensions)}
    ${lib.concatStrings (lib.mapAttrsToList (name: path: ''
        cp -L ${path} $out/bin/${name}
      '')
      seedBin)}
  '';

  # How omp-bot's boxed bots reach the box (bin/omp-bot-box): the same key and port the omp wrapper uses.
  sshConfig = pkgs.writeText "omp-box-ssh-config" ''
    Host *
      HostName 127.0.0.1
      Port ${toString box.port}
      User ${user}
      IdentityFile ${box.state}/ssh-key
      IdentitiesOnly yes
      BatchMode yes
      LogLevel ERROR
      UserKnownHostsFile /dev/null
      StrictHostKeyChecking no
      ConnectTimeout 5
      ServerAliveInterval 10
      ServerAliveCountMax 3
  '';

  mkBox = {
    state,
    port,
  }: let
    guest = flakeInputs.nixpkgs.lib.nixosSystem {
      specialArgs.ompBox = {
        inherit user port seedMount;
        # The seed share's host side, which omp-box-seed fills.
        seedDir = "${state}/seed";
        inherit shares;
        # Headless Chromium the box keeps running, each with its DevTools on 127.0.0.1:PORT inside the box
        # for a boxed bot's browser.cdpUrl. A profile lives on a share (a bot's persist path), and its browser
        # waits until that share is mounted.
        browsers.baobot = {
          profile = "${home}/.local/state/baobot/chromium";
          port = 9222;
        };
        sharesDir = "${state}/shares";
        authDir = "${state}/auth";
        nativesDir = "${state}/natives";
        # Box sessions' ompd jobs (omp-bot's omp/ompd.ts, which starts an ompd in the box), kept on the host so
        # a job's record and log outlive a box restart and a cut-off job is reported instead of forgotten.
        ompdJobsDir = "${state}/ompd-jobs";
        inherit (inputPackages.oh-my-pi) omp;
      };
      modules = [
        {nixpkgs.pkgs = pkgs;}
        flakeInputs.microvm.nixosModules.microvm
        ../../../../omp-box/guest.nix
      ];
    };
    runner = guest.config.microvm.declaredRunner;
  in {
    inherit guest runner state port;
    run = pkgs.writeShellScript "omp-box-run" ''
      set -Eeuo pipefail
      export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.gnugrep pkgs.iproute2 pkgs.openssh pkgs.jq]}
      status=${state}/status.json
      runner=${runner}
      limit=3
      qemu=
      stopping=0
      timedout=0

      record() {
        jq -n --arg state "$1" --arg reason "$2" --argjson failures "$3" --argjson updated "$(date +%s%3N)" --arg runner "$runner" \
          '{state: $state, reason: (if $reason == "" then null else $reason end), failures: $failures, updated: $updated, runner: $runner}' >"$status.tmp"
        mv -f "$status.tmp" "$status"
      }

      recorded_failures() {
        if [ -f "$status" ] && [ "$(jq -r '.runner // empty' "$status" 2>/dev/null)" = "$runner" ]; then
          jq -r '.failures // 0' "$status" 2>/dev/null || echo 0
        else
          echo 0
        fi
      }

      blocked() {
        [ -f "$status" ] || return 1
        [ "$(jq -r '.state + " " + .runner' "$status" 2>/dev/null || true)" = "failed $runner" ]
      }

      hold() {
        while blocked; do
          sleep 5 &
          wait $! || true
        done
      }

      fail() {
        trap - ERR
        local reason=$1 count=$((previous + 1))
        if [ "$count" -ge "$limit" ]; then
          reason="$reason; gave up after $count failed starts in a row (omp-box retry to try again)"
          echo "omp-box: $reason" >&2
          record failed "$reason" "$count" || echo "omp-box: could not write $status" >&2
          hold
        else
          echo "omp-box: $reason" >&2
          record crashed "$reason" "$count" || echo "omp-box: could not write $status" >&2
        fi
        exit 1
      }

      on_signal() {
        [ -n "$qemu" ] || exit 0
        stopping=1
        kill -TERM "$qemu" 2>/dev/null || true
      }

      trap on_signal TERM INT
      trap '[ -z "$qemu" ] || kill -TERM "$qemu" 2>/dev/null || true' EXIT

      previous=0
      hold
      previous=$(recorded_failures)
      trap 'fail "setup failed at line $LINENO: $BASH_COMMAND (exit $?)"' ERR

      mkdir -p ${state}/shares ${state}/grants ${state}/natives ${state}/auth ${state}/ompd-jobs ${state}/seed ${home}/.omp/natives
      rm -f ${state}/id_ed25519
      [ -f ${state}/ssh-key ] || ssh-keygen -q -t ed25519 -N "" -C omp-box -f ${state}/ssh-key
      cp ${state}/ssh-key.pub ${state}/auth/authorized_keys
      cp -al ${home}/.omp/natives/. ${state}/natives/ 2>/dev/null || cp -a ${home}/.omp/natives/. ${state}/natives/
      free=0
      for _ in $(seq 60); do
        if [ -z "$(ss -Hltn 'sport = :${toString port}')" ]; then
          free=1
          break
        fi
        sleep 0.5
      done
      [ "$free" = 1 ] || fail "127.0.0.1:${toString port} is still taken after 30s, so the box cannot forward its sshd there"
      rm -f ${state}/omp-box.sock
      cd ${state}

      record starting "" "$previous"
      : >${state}/qemu.err
      exec 3> >(exec tee -a ${state}/box.log ${state}/qemu.err >&2)
      tee=$!
      started=$(date +%s)
      ${runner}/bin/microvm-run </dev/null >${state}/console.log 2>&3 &
      qemu=$!

      up=0
      while kill -0 "$qemu" 2>/dev/null; do
        lived=$(($(date +%s) - started))
        if [ "$up" = 0 ]; then
          if timeout 10 ssh -q -p ${toString port} -i ${state}/ssh-key \
               -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
               -o BatchMode=yes -o ConnectTimeout=1 -o ServerAliveInterval=2 -o ServerAliveCountMax=1 ${user}@127.0.0.1 \
               mountpoint -q /mnt/shares 2>/dev/null; then
            up=1
            record up "" "$previous"
          elif [ "$lived" -ge 300 ] && [ "$timedout" = 0 ]; then
            timedout=1
            kill -TERM "$qemu" 2>/dev/null || true
          fi
        elif [ "$up" = 1 ] && [ "$lived" -ge 120 ]; then
          up=2
          previous=0
          record up "" 0
        fi
        sleep 1 &
        wait $! || true
      done

      rc=0
      wait "$qemu" || rc=$?
      qemu=
      exec 3>&-
      wait "$tee" 2>/dev/null || true
      lived=$(($(date +%s) - started))
      if [ "$stopping" = 1 ]; then
        rm -f "$status"
        exit 0
      fi
      last=$(grep -v -e '^[[:space:]]*$' -e 'terminating on signal' ${state}/qemu.err | tail -n 1 || true)
      [ "$timedout" = 0 ] || fail "the guest's sshd did not answer on 127.0.0.1:${toString port} within 300s (see ${state}/console.log)"
      [ "$up" != 0 ] || fail "qemu exited with code $rc before the guest's sshd answered on 127.0.0.1:${toString port}''${last:+: $last}"
      [ "$rc" = 0 ] || [ "$lived" -ge 120 ] || fail "qemu exited with code $rc after ''${lived}s''${last:+: $last}"
      echo "omp-box: qemu exited with code $rc after ''${lived}s''${last:+: $last}" >&2
      record crashed "qemu exited with code $rc after ''${lived}s''${last:+: $last}" 0
      exit 1
    '';
  };

  box = mkBox {
    state = "${home}/.local/state/omp-box";
    port = 22422;
  };

  pkg = pkgs.callPackage ../../../../omp-box {
    inherit user;
    inherit shares;
    inherit generators;
    inherit (inputPackages.oh-my-pi) omp;
  };

  selftestBox = mkBox {
    state = "/tmp/omp-box-selftest/omp-box";
    port = 22499;
  };
  selftest = pkgs.writeShellApplication {
    name = "omp-box-selftest";
    runtimeInputs = [pkgs.coreutils pkgs.gnugrep pkgs.iproute2 pkgs.openssh pkgs.jq];
    text = ''
      root=${builtins.dirOf selftestBox.state}
      state=${selftestBox.state}
      status=$state/status.json
      port=${toString selftestBox.port}
      home=''${HOME:?omp-box-selftest needs HOME}
      work=$(mktemp -d)
      pid=
      failed=0

      pass() { echo "PASS: $*"; }
      flunk() {
        echo "FAIL: $*"
        failed=1
      }
      die() {
        echo "FAIL: $*"
        exit 1
      }
      cleanup() {
        if [ -n "$pid" ]; then
          kill -TERM "$pid" 2>/dev/null || true
          wait "$pid" 2>/dev/null || true
        fi
        [ ! -d "$state/ompd-jobs" ] || chmod 700 "$state/ompd-jobs"
        rm -rf "$root" "$work"
      }
      trap cleanup EXIT
      box() {
        ssh -q -p "$port" -i "$state/ssh-key" -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
          -o BatchMode=yes -o ConnectTimeout=5 ${user}@127.0.0.1 "$@"
      }
      field() { jq -r ".$1 // empty" "$status" 2>/dev/null || true; }
      await_state() {
        local want=$1 secs=$2
        for _ in $(seq "$secs"); do
          [ "$(field state)" = "$want" ] && return 0
          [ -z "$pid" ] || kill -0 "$pid" 2>/dev/null || return 1
          sleep 1
        done
        return 1
      }
      boot() {
        env -i HOME="$home" ${selftestBox.run} </dev/null >"$1" 2>&1 &
        pid=$!
      }

      [ -z "$(ss -Hltn "sport = :$port")" ] || die "127.0.0.1:$port is already taken"

      echo "== a) fresh state, env -i like finit"
      rm -rf "$root"
      boot "$work/a.log"
      if await_state up 180; then
        pass "status.json reached up ($(jq -c . "$status"))"
      else
        echo "--- run-script output:"
        tail -n 20 "$work/a.log"
        die "status.json did not reach up within 180s (state: $(field state), reason: $(field reason))"
      fi
      if [ "$(field runner)" = ${selftestBox.runner} ]; then pass "status.json names the runner"; else flunk "status.json runner is $(field runner)"; fi
      if box true; then pass "ssh into the box works"; else flunk "ssh into the box failed"; fi
      for mount in ${lib.escapeShellArgs (map (s: s.mountPoint) selftestBox.guest.config.microvm.shares)}; do
        if box mountpoint -q "$mount"; then pass "share mounted at $mount"; else flunk "share not mounted at $mount"; fi
      done
      kill -TERM "$pid"
      rc=0
      wait "$pid" || rc=$?
      pid=
      if [ "$rc" = 0 ]; then pass "TERM stops the box with exit 0"; else flunk "TERM left exit code $rc"; fi
      if [ ! -e "$status" ]; then pass "a clean stop clears status.json"; else flunk "status.json after stop: $(jq -c . "$status")"; fi
      if [ -z "$(ss -Hltn "sport = :$port")" ]; then pass "qemu released 127.0.0.1:$port"; else flunk "127.0.0.1:$port still taken after stop"; fi

      echo "== b) unusable share source"
      rm -rf "$state/ompd-jobs"
      : >"$state/ompd-jobs"
      for attempt in 1 2; do
        rc=0
        env -i HOME="$home" ${selftestBox.run} </dev/null >"$work/b$attempt.log" 2>&1 || rc=$?
        if [ "$rc" != 0 ]; then pass "attempt $attempt exits $rc"; else flunk "attempt $attempt exited 0"; fi
        if grep -q '^omp-box: ' "$work/b$attempt.log"; then
          pass "attempt $attempt says: $(grep '^omp-box: ' "$work/b$attempt.log" | tail -n 1)"
        else
          flunk "attempt $attempt printed no omp-box: error"
        fi
        if [ "$(field state)/$(field failures)" = "crashed/$attempt" ]; then pass "status crashed, failures $attempt"; else flunk "status after attempt $attempt: $(jq -c . "$status")"; fi
      done
      boot "$work/b3.log"
      if await_state failed 30; then
        pass "attempt 3 marks the box failed: $(field reason)"
      else
        flunk "attempt 3 did not mark the box failed: $(jq -c . "$status" 2>/dev/null)"
      fi
      if [ "$(field failures)" = 3 ]; then pass "failures 3"; else flunk "failures $(field failures)"; fi
      if field reason | grep -q 'omp-box retry'; then pass "the reason points at omp-box retry"; else flunk "the reason does not mention omp-box retry"; fi
      sleep 8
      if kill -0 "$pid" 2>/dev/null; then pass "the failed run blocks instead of exiting"; else flunk "the failed run exited, so finit would respawn it"; fi
      if env -i HOME="$home" XDG_STATE_HOME="$root" ${pkg}/bin/omp-box retry; then pass "omp-box retry clears the failure"; else flunk "omp-box retry failed"; fi
      unblocked=0
      for _ in $(seq 15); do
        if ! kill -0 "$pid" 2>/dev/null; then
          unblocked=1
          break
        fi
        sleep 1
      done
      if [ "$unblocked" = 1 ]; then
        rc=0
        wait "$pid" || rc=$?
        pid=
        pass "retry unblocks the waiting run (exit $rc, finit respawns it)"
      else
        flunk "the run still waits after omp-box retry"
      fi
      retry=0
      env -i HOME="$home" XDG_STATE_HOME="$root" ${pkg}/bin/omp-box retry >/dev/null 2>&1 || retry=$?
      if [ "$retry" != 0 ]; then pass "omp-box retry refuses when the box is not failed"; else flunk "omp-box retry succeeded on a box that is not failed"; fi

      echo "== c) share source qemu cannot open"
      rm -f "$state/ompd-jobs"
      mkdir "$state/ompd-jobs"
      chmod 000 "$state/ompd-jobs"
      rc=0
      env -i HOME="$home" ${selftestBox.run} </dev/null >"$work/c.log" 2>&1 || rc=$?
      if [ "$rc" != 0 ]; then pass "the run exits $rc"; else flunk "the run exited 0"; fi
      if [ "$(field state)/$(field failures)" = crashed/1 ]; then pass "status crashed, failures 1"; else flunk "status: $(jq -c . "$status")"; fi
      if field reason | grep -q 'fsdev'; then pass "the reason carries qemu's error: $(field reason)"; else flunk "the reason lacks qemu's error: $(field reason)"; fi
      if grep -q 'fsdev' "$state/box.log"; then pass "qemu's stderr is in box.log"; else flunk "box.log lacks qemu's stderr"; fi

      if [ "$failed" = 0 ]; then echo "omp-box-selftest: all passed"; else die "omp-box-selftest: some checks failed"; fi
    '';
  };
in {
  config = {
    user.persist.directories = [".local/state/omp-box"];
    finix.persistence.homeServices = ["omp-box" "omp-box-grants" "omp-box-proxy" "omp-box-seed"];
    environment.systemPackages = [pkg];
    system.build.ompBoxRunner = box.runner;
    system.build.ompBoxSelftest = selftest;
    system.build.ompBox = pkg;

    user.files.".config/omp-bot/box.env".text = ''
      export OMP_BOT_BOX_SSH_CONFIG=${sshConfig}
      export OMP_BOT_BOX_STATUS=${box.state}/status.json
      export OMP_BOT_BOX_EXT=${seedMount}/current/ext
      export OMP_BOT_BOX_PATH=${seedMount}/current/bin
      unset OMP_BOT_EXTENSION OMPD_SERVICE
    '';

    finit.services.omp-box-grants = {
      description = "re-apply omp box folder grants";
      inherit user;
      reload-signal = "none";
      respawn = true;
      log = true;
      environment = {
        HOME = home;
        XDG_STATE_HOME = "${home}/.local/state";
      };
      command = "${pkgs.writeShellScript "omp-box-grants" ''
        set -euo pipefail
        export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.openssh]}
        while :; do
          if ssh -q -p ${toString box.port} -i ${box.state}/ssh-key \
               -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
               -o BatchMode=yes -o ConnectTimeout=1 -o ServerAliveInterval=2 -o ServerAliveCountMax=1 ${user}@127.0.0.1 \
               mountpoint -q /mnt/shares 2>/dev/null; then
            if ${pkg}/bin/omp-box reconcile; then
              sleep 30
            else
              echo "omp-box-grants: omp-box reconcile failed, trying again in 2s" >&2
              sleep 2
            fi
          else
            sleep 2
          fi
        done
      ''}";
    };

    # Copies the seed into the box's seed share whenever it changes (finit restarts this service, not omp-box,
    # on a switch that changes it): a new generation, then current pointed at it, then the box's omp-seed run
    # again so its omp config names it. The ten newest generations stay, since a box session or the box's ompd
    # may still run code from an older one; a box that is down reads current when it boots.
    finit.services.omp-box-seed = {
      description = "copy what omp in the box loads into its seed share";
      inherit user;
      reload-signal = "none";
      respawn = true;
      log = true;
      environment.HOME = home;
      command = "${pkgs.writeShellScript "omp-box-seed" ''
        set -euo pipefail
        export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.findutils pkgs.openssh]}
        trap 'echo "omp-box-seed: failed at line $LINENO: $BASH_COMMAND" >&2' ERR
        dir=${box.state}/seed
        gen=${builtins.baseNameOf seed}
        mkdir -p "$dir"
        if [ ! -d "$dir/$gen" ]; then
          rm -rf "$dir/.in"
          cp -r ${seed} "$dir/.in"
          chmod -R u+w,go+rX "$dir/.in"
          mv -T "$dir/.in" "$dir/$gen"
        fi
        touch "$dir/$gen"
        ln -sfn "$gen" "$dir/.current"
        mv -T "$dir/.current" "$dir/current"
        find "$dir" -mindepth 1 -maxdepth 1 -type d -name '*-omp-box-seed' -printf '%T@ %p\n' | sort -rn | tail -n +11 | cut -d' ' -f2- | xargs -r rm -rf
        if ssh -q -p ${toString box.port} -i ${box.state}/ssh-key \
             -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
             -o BatchMode=yes -o ConnectTimeout=5 ${user}@127.0.0.1 sudo -n systemctl restart omp-seed 2>/dev/null; then
          echo "omp-box-seed: the box now loads $gen"
        else
          echo "omp-box-seed: $gen is in place; the box is not up, so it reads it when it boots"
        fi
        exec sleep infinity
      ''}";
    };

    finit.services.omp-box-proxy = {
      description = "omp gateway proxy";
      inherit user;
      reload-signal = "none";
      respawn = true;
      log = true;
      environment = {
        GATEWAY_KEY_FILE = "${home}/Tokens/AI_GATEWAY_API_KEY.txt";
        CREST_AUTH = "${inputPackages.crest.crest-auth}/bin/crest-auth";
        HOME = home;
      };
      command = "${proxy}/bin/omp-gateway-proxy";
    };
    finit.services.omp-botd.path = [pkg];

    finit.services.omp-box = {
      description = "omp NixOS microVM";
      inherit user;
      reload-signal = "none";
      respawn = true;
      log = true;
      environment.HOME = home;
      command = "${box.run}";
    };
  };
}

{
  config,
  flakeInputs,
  lib,
  pkgs,
  ...
}: let
  userName = config.user.name;
  home = config.user.homeDirectory;
  inherit (config.user) runtimeDir;
  # A headed Chromium on the desktop that baobot, in omp-box, drives for Taobao over DevTools. It binds
  # 127.0.0.1 only; QEMU's user networking hands the box the host's loopback as 10.0.2.2, as it does the
  # model gateway on 8899, so the box reaches it and the LAN never does. Its own profile, apart from the
  # everyday browser's, and apart from the box's own headless browser-baobot on 9222.
  #
  # Nothing starts it at boot: a browser no one asked for costs a few hundred MB of RAM for the whole
  # session. What holds the port the box reaches (9233) is `broker`: a connection there starts the
  # browser when it is down and then carries the connection to its DevTools, which listens on 9234. So
  # a bot that just connects finds a browser, and every bot in the box shares that one browser. The
  # desktop entry, or `baobot-chromium` on a shell, starts the same browser and opens a window in it.
  port = 9233;
  devtoolsPort = 9234;
  state = "${home}/.local/state/baobot-desktop";
  profile = "${state}/chromium";
  url = "https://www.taobao.com";
  appId = "baobot-chromium";

  # Chromium if it is not already up, in the desktop session. It is the only thing that starts the
  # browser, so the browser starts the same way whoever asked: the broker, the desktop entry, or a
  # shell. Callers that arrive together wait on the lock and share the one browser.
  ensure = pkgs.writeShellScriptBin "baobot-chromium-ensure" ''
    set -eu
    PATH=${lib.makeBinPath [pkgs.coreutils pkgs.curl pkgs.procps pkgs.util-linux]}:$PATH
    port=${toString devtoolsPort}
    profile=${profile}
    log=${state}/chromium.log

    [ "$#" -gt 0 ] || set -- ${url}

    devtools() { curl -fsS -m 1 "http://127.0.0.1:$port/json/version" >/dev/null 2>&1; }
    # Chromium's own path in the pattern, so a process that only mentions the profile in its arguments
    # is not mistaken for the browser.
    running() { pgrep -f -- "chromium.*--user-data-dir=$profile" >/dev/null; }

    devtools && exit 0

    mkdir -p ${state}
    exec 9>${state}/chromium.lock
    ${pkgs.util-linux}/bin/flock 9
    devtools && exit 0

    if ! running; then
      # Started from a service or a tty, ahead of the session: give the compositor a few seconds to appear.
      if [ -z "''${WAYLAND_DISPLAY:-}" ]; then
        export WAYLAND_DISPLAY=tomoe-0
        export XDG_SESSION_TYPE=wayland
        export NIXOS_OZONE_WL=1
        export XDG_RUNTIME_DIR=${runtimeDir}
        export DBUS_SESSION_BUS_ADDRESS=unix:path=${runtimeDir}/tomoe.tomoe-0.bus
        for _ in $(seq 1 20); do
          ${pkgs.wayland-utils}/bin/wayland-info >/dev/null 2>&1 && break
          sleep 0.5
        done
      fi

      # 9>&- so the browser does not hold the lock above for as long as it runs.
      setsid ${lib.getExe pkgs.ungoogled-chromium} \
        --user-data-dir="$profile" \
        --remote-debugging-port="$port" \
        --class=${appId} \
        --no-first-run \
        --no-default-browser-check \
        "$@" </dev/null >"$log" 2>&1 9>&- &
    fi

    # Report only once the browser answers, so a caller that wants DevTools can use it right away.
    for _ in $(seq 1 240); do
      devtools && exit 0
      # A second launch loses the profile lock and exits, leaving the first browser as this one; the
      # lock also holds while the browser boots, so only give up when no browser owns the profile.
      if ! running; then
        devtools && exit 0
        echo "baobot-chromium: the browser exited before DevTools answered; see $log" >&2
        tail -n 20 "$log" >&2 || true
        exit 1
      fi
      sleep 0.25
    done
    echo "baobot-chromium: DevTools on 127.0.0.1:$port did not answer; see $log" >&2
    exit 1
  '';

  launcher = pkgs.writeShellScriptBin "baobot-chromium" ''
    set -eu
    PATH=${lib.makeBinPath [pkgs.curl]}:$PATH
    port=${toString devtoolsPort}
    profile=${profile}

    [ "$#" -gt 0 ] || set -- ${url}

    if curl -fsS -m 1 "http://127.0.0.1:$port/json/version" >/dev/null 2>&1; then
      # Already up: Chromium hands this command line to the running instance through the profile's
      # singleton lock, which opens a window there, and this process exits.
      exec ${lib.getExe pkgs.ungoogled-chromium} --user-data-dir="$profile" --class=${appId} "$@"
    fi
    exec ${lib.getExe ensure} "$@"
  '';

  broker = pkgs.writers.writePython3Bin "baobot-chromium-broker" {} (builtins.readFile ./baobot-chromium-broker.py);
in {
  environment.systemPackages = [launcher];

  finix.persistence.homeServices = ["baobot-chromium"];

  user = {
    persist.directories = [".local/state/baobot-desktop"];

    ui.tomoe.extraConfig =
      builtins.readFile "${flakeInputs.tomoe}/examples/special.lisp"
      + ''
        (setf +special-bindings+ '(("t" :taobao :park nil)))
        (define-extension "baobot-chromium" (:reads ()) (snapshot state event)
          (declare (ignore snapshot event))
          (values state
                  (list (window-rule :baobot-chromium :app-id "${appId}" :properties '((:special . "taobao"))))
                  nil))
      '';

    files = {
      ".local/state/omp-bot/bots/baobot/config.yml" = {
        generator = lib.generators.toYAML {};
        value.browser.cdpUrl = "http://10.0.2.2:${toString port}";
      };
      ".local/share/applications/baobot-chromium.desktop" = {
        generator = lib.generators.toINI {};
        value."Desktop Entry" = {
          Name = "Taobao (baobot)";
          Exec = lib.getExe launcher;
          Terminal = false;
          Type = "Application";
          Categories = "Network;WebBrowser;";
          StartupWMClass = appId;
          Comment = "baobot's Chromium for Taobao; starts it unless DevTools on 127.0.0.1:${toString devtoolsPort} answers";
        };
      };
    };
  };

  # What the box connects to at 10.0.2.2:${port}: the browser starts when that port is asked for, and
  # nothing else on the host is reachable from the box through it.
  finit.services.baobot-chromium = {
    description = "baobot's Taobao Chromium, started when the box connects (${userName})";
    user = userName;
    group = "users";
    environment = {
      HOME = home;
      XDG_RUNTIME_DIR = runtimeDir;
      BAOBOT_CHROMIUM_PORT = toString port;
      BAOBOT_CHROMIUM_DEVTOOLS_PORT = toString devtoolsPort;
      BAOBOT_CHROMIUM_ENSURE = lib.getExe ensure;
    };
    command = "${broker}/bin/baobot-chromium-broker";
    respawn = true;
    restart-sec = 5;
    reload-signal = "none";
    log = true;
  };
}

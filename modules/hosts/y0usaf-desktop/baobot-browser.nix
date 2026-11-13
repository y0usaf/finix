{
  config,
  flakeInputs,
  lib,
  pkgs,
  ...
}: let
  home = config.user.homeDirectory;
  inherit (config.user) runtimeDir;
  # A headed Chromium on the desktop that baobot, in omp-box, drives for Taobao over DevTools. It binds
  # 127.0.0.1 only; QEMU's user networking hands the box the host's loopback as 10.0.2.2, as it does the
  # model gateway on 8899, so the box reaches it and the LAN never does. Its own profile, apart from the
  # everyday browser's, and apart from the box's own headless browser-baobot on 9222.
  #
  # Nothing starts it at boot: the desktop entry, or `baobot-chromium` on a shell, starts the browser
  # when DevTools is not answering and only opens a window when it already is. A browser that no one
  # asked for costs a few hundred MB of RAM for the whole session, so it waits to be asked.
  port = 9233;
  profile = "${home}/.local/state/baobot-desktop/chromium";
  url = "https://www.taobao.com";
  appId = "baobot-chromium";
  chromium = pkgs.writeShellScriptBin "baobot-chromium" ''
    set -eu
    PATH=${lib.makeBinPath [pkgs.coreutils pkgs.curl pkgs.procps pkgs.util-linux]}:$PATH
    port=${toString port}
    profile=${profile}

    [ "$#" -gt 0 ] || set -- ${url}

    devtools() { curl -fsS -m 1 "http://127.0.0.1:$port/json/version" >/dev/null 2>&1; }
    running() { pgrep -f -- "--user-data-dir=$profile" >/dev/null; }

    if devtools; then
      # Already up: Chromium hands this command line to the running instance through the profile's
      # singleton lock, which opens a window there, and this process exits.
      exec ${lib.getExe pkgs.chromium} --user-data-dir="$profile" --class=${appId} "$@"
    fi

    # Started from a tty, ahead of the session: give the compositor a few seconds to appear.
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

    log="''${XDG_RUNTIME_DIR:-/tmp}/baobot-chromium.log"
    setsid ${lib.getExe pkgs.chromium} \
      --user-data-dir="$profile" \
      --remote-debugging-port="$port" \
      --class=${appId} \
      --no-first-run \
      --no-default-browser-check \
      "$@" </dev/null >"$log" 2>&1 &

    # Report only once the browser answers, so a caller that wants DevTools can use it right away.
    for _ in $(seq 1 60); do
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
in {
  environment.systemPackages = [chromium];

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
          Exec = lib.getExe chromium;
          Terminal = false;
          Type = "Application";
          Categories = "Network;WebBrowser;";
          StartupWMClass = appId;
          Comment = "baobot's Chromium for Taobao; starts it unless DevTools on 127.0.0.1:${toString port} answers";
        };
      };
    };
  };
}

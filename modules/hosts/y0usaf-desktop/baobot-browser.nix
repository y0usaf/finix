{
  config,
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
  port = 9233;
  profile = "${home}/.local/state/baobot-desktop/chromium";
  url = "https://www.taobao.com";
  chromium = pkgs.writeShellScriptBin "baobot-chromium" ''
    exec ${lib.getExe pkgs.chromium} \
      --user-data-dir=${profile} \
      --remote-debugging-port=${toString port} \
      --no-first-run \
      --no-default-browser-check \
      "$@"
  '';
in {
  user.persist.directories = [".local/state/baobot-desktop"];
  finix.persistence.homeServices = ["baobot-chromium"];

  environment.systemPackages = [chromium];

  user.files = {
    ".local/state/omp-bot/bots/baobot/config.yml" = {
      generator = lib.generators.toYAML {};
      value.browser.cdpUrl = "http://10.0.2.2:${toString port}";
    };
    ".local/share/applications/baobot-chromium.desktop" = {
      generator = lib.generators.toINI {};
      value."Desktop Entry" = {
        Name = "Taobao (baobot)";
        Exec = "${lib.getExe chromium} ${url}";
        Terminal = false;
        Type = "Application";
        Categories = "Network;WebBrowser;";
        Comment = "baobot's Chromium for Taobao, DevTools on 127.0.0.1:${toString port}";
      };
    };
  };

  # Running all session long, a launch from the desktop entry opens a window in this one.
  finit.services.baobot-chromium = {
    description = "baobot's Taobao Chromium, DevTools on 127.0.0.1:${toString port} (${userName})";
    # Chromium quits on SIGHUP, so a changed unit is stopped and started instead.
    reload-signal = "none";
    user = userName;
    group = "users";
    environment = {
      HOME = home;
      XDG_RUNTIME_DIR = runtimeDir;
      WAYLAND_DISPLAY = "tomoe-0";
      DBUS_SESSION_BUS_ADDRESS = "unix:path=${runtimeDir}/tomoe.tomoe-0.bus";
      NIXOS_OZONE_WL = "1";
    };
    command = "${pkgs.writeShellScript "baobot-chromium-start" ''
      until [ -S ${runtimeDir}/tomoe-0 ]; do
        ${pkgs.coreutils}/bin/sleep 2
      done
      exec ${lib.getExe chromium} ${url}
    ''}";
    respawn = true;
    log = true;
  };
}

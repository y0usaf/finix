{
  config,
  lib,
  pkgs,
  ...
}: let
  userName = config.user.name;
  home = config.user.homeDirectory;
  inherit (config.user) runtimeDir;
  latitude = "43.65";
  longitude = "-79.38";

  gammastep = "${pkgs.gammastep}/bin/gammastep";

  modeScript = pkgs.writeShellScript "darkman-theme" ''
    case "$1" in
      light) exec ${config.user.theme.apply "light"} ;;
      dark) exec ${config.user.theme.apply "dark"} ;;
    esac
  '';

  darkmanConfig = pkgs.writeTextDir "darkman/config.yaml" ''
    lat: ${latitude}
    lng: ${longitude}
    usegeoclue: false
    portal: false
  '';

  darkmanScripts = pkgs.linkFarm "darkman-scripts" [
    {
      name = "darkman/theme";
      path = modeScript;
    }
  ];

  waitFor = socket: program:
    pkgs.writeShellScript "wait-for-${baseNameOf socket}" ''
      until [ -S ${socket} ]; do
        ${pkgs.coreutils}/bin/sleep 2
      done
      exec ${program}
    '';

  darkmanCli = pkgs.runCommand "darkman-cli" {} ''
    mkdir -p $out/bin
    ln -s ${pkgs.darkman}/bin/darkman $out/bin/darkman
  '';

  nightLightToggle = pkgs.writeShellScript "night-light-toggle" ''
    exec ${pkgs.procps}/bin/pkill -USR1 -u ${userName} -f '^${gammastep} '
  '';

  sessionEnvironment = {
    HOME = home;
    XDG_RUNTIME_DIR = runtimeDir;
  };
in {
  finix.persistence.homeServices = ["darkman" "gammastep"];

  environment.systemPackages = [darkmanCli pkgs.gammastep];

  finit.services = {
    darkman = {
      description = "darkman light and dark theme at sunrise and sunset (${userName})";
      user = userName;
      group = "users";
      environment =
        sessionEnvironment
        // {
          XDG_CONFIG_DIRS = "${darkmanConfig}";
          XDG_DATA_DIRS = "${darkmanScripts}";
          DBUS_SESSION_BUS_ADDRESS = "unix:path=${runtimeDir}/tomoe.tomoe-0.bus";
        };
      command = "${waitFor "${runtimeDir}/tomoe.tomoe-0.bus" "${pkgs.darkman}/bin/darkman run"}";
      respawn = true;
      log = true;
    };

    gammastep = {
      description = "gammastep warm screen at night (${userName})";
      user = userName;
      group = "users";
      environment =
        sessionEnvironment
        // {
          WAYLAND_DISPLAY = "tomoe-0";
        };
      command = "${waitFor "${runtimeDir}/tomoe-0" "${gammastep} -m wayland -l ${latitude}:${longitude} -t 6500:3400 -v"}";
      respawn = true;
      log = true;
    };
  };

  user.ui.tomoe.extraConfig = ''
    (define-extension "night-light" (:reads (:key)) (snapshot state event)
      (declare (ignore snapshot))
      (values state
              (list (bind-key (list :alt) "n" :press :description "Toggle Night Light"))
              (when (and (eq (getf event :type) :key) (equal (getf event :owner) "night-light"))
                (list (launch "${nightLightToggle}")))))
  '';
}

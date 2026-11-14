{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.user.daylight;
  userName = config.user.name;
  home = config.user.homeDirectory;
  inherit (config.user) runtimeDir;
  inherit (cfg) latitude longitude;

  gammastep = "${pkgs.gammastep}/bin/gammastep";

  themeMode = pkgs.writeShellScript "theme-mode" ''
    exec ${pkgs.gawk}/bin/awk -v lat=${lib.escapeShellArg latitude} -v lng=${lib.escapeShellArg longitude} \
      -v now="''${1:-$(${pkgs.coreutils}/bin/date +%s)}" '
      function rad(x) { return x * 3.14159265358979 / 180 }
      function deg(x) { return x * 180 / 3.14159265358979 }
      function asin(x) { return atan2(x, sqrt(1 - x * x)) }
      BEGIN {
        n = now / 86400 + 2440587.5 - 2451545.0
        L = 280.460 + 0.9856474 * n
        g = 357.528 + 0.9856003 * n
        lam = L + 1.915 * sin(rad(g)) + 0.020 * sin(rad(2 * g))
        eps = 23.439 - 0.0000004 * n
        decl = asin(sin(rad(eps)) * sin(rad(lam)))
        ra = atan2(cos(rad(eps)) * sin(rad(lam)), cos(rad(lam)))
        gmst = 18.697374558 + 24.06570982441908 * n
        hour = gmst * 15 + lng - deg(ra)
        elevation = deg(asin(sin(rad(lat)) * sin(decl) + cos(rad(lat)) * cos(decl) * cos(rad(hour))))
        print (elevation > -0.833 ? "light" : "dark")
      }'
  '';

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

  untilWayland = program:
    pkgs.writeShellScript "wait-for-wayland" ''
      until ${pkgs.coreutils}/bin/timeout 5 ${pkgs.wayland-utils}/bin/wayland-info >/dev/null 2>&1; do
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
  options.user.daylight = {
    latitude = lib.mkOption {
      type = lib.types.str;
      default = "43.65";
      description = "Latitude that sunlight, the theme mode and the night light follow; decimal degrees.";
    };

    longitude = lib.mkOption {
      type = lib.types.str;
      default = "-79.38";
      description = "Longitude that sunlight, the theme mode and the night light follow; decimal degrees, west negative.";
    };

    mode = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = "${themeMode}";
      description = "Shell command that prints light or dark for the sun's position at the configured latitude and longitude at the moment it runs; an optional unix epoch argument asks for another instant instead of now.";
    };
  };

  config = {
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
        command = "${untilWayland "${gammastep} -m wayland -l ${latitude}:${longitude} -t 6500:3400 -v"}";
        respawn = true;
        restart-sec = 10;
        log = true;
      };
    };

    user.ui.tomoe.extraConfig = ''
    (define-extension "night-light" (:reads (:command)) (snapshot state event)
      (declare (ignore snapshot))
      (values state
              (list (define-command "toggle-night-light" :description "Toggle the night light filter.")
                    (bind-key (list :alt) "n" "toggle-night-light" :description "Toggle Night Light"))
              (when (and (eq (getf event :type) :command)
                         (equal (getf event :name) "toggle-night-light"))
                (list (launch "${nightLightToggle}")))))
    '';
  };
}

{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  sys = pkgs.stdenv.hostPlatform.system;
  userName = config.user.name;
  user = config.users.users.${userName};
  runtimeDir = "/run/user/${toString user.uid}";

  tomoePkg = flakeInputs.tomoe.packages."${sys}".default;

  tomoePortalPkg =
    pkgs.runCommand "tomoe-portal" {
      meta.description = "xdg-desktop-portal ScreenCast backend metadata for tomoe";
    } ''
      install -Dm644 ${tomoePkg}/share/xdg-desktop-portal/portals/tomoe.portal \
        $out/share/xdg-desktop-portal/portals/tomoe.portal
      install -Dm644 ${tomoePkg}/share/xdg-desktop-portal/tomoe-portals.conf \
        $out/share/xdg-desktop-portal/tomoe-portals.conf
      install -Dm644 ${tomoePkg}/share/dbus-1/services/org.freedesktop.impl.portal.desktop.tomoe.service \
        $out/share/dbus-1/services/org.freedesktop.impl.portal.desktop.tomoe.service
    '';

  starterPolicy = pkgs.writeText "tomoe-init.lisp" config.user.ui.tomoe.lisp.initText;
in {
  finit.services.seatd.runlevels = lib.mkForce "234";

  xdg.portal.portals = [pkgs.xdg-desktop-portal-gtk tomoePortalPkg];

  environment.etc."xdg/xdg-desktop-portal/tomoe-portals.conf".text = ''
    [preferred]
    default=*
    org.freedesktop.impl.portal.ScreenCast=tomoe
  '';

  finit.tasks.xdg-runtime-dir = lib.mkIf (!config.services.elogind.enable) {
    description = "runtime dir for ${userName}";
    command = pkgs.writeShellScript "xdg-runtime-dir" ''
      export PATH=${lib.makeBinPath [pkgs.coreutils]}
      install -d -m 0700 -o ${userName} -g users ${runtimeDir}
    '';
    log = true;
  };
  environment = {
    etc."profile.d/xdg-runtime-dir.sh".text = ''
      if [ -z "''${XDG_RUNTIME_DIR:-}" ]; then
        export XDG_RUNTIME_DIR="/run/user/$(id -u)"
      fi
    '';
    etc."profile.d/display.sh".text = ''
      if [ -z "''${DISPLAY:-}" ]; then
        for _x in /tmp/.X11-unix/X*; do
          [ -S "$_x" ] || continue
          export DISPLAY=":''${_x##*/X}"
          break
        done
        unset _x
      fi
    '';
    systemPackages = [
      tomoePkg
      (pkgs.writeShellScriptBin "tomoe-session" ''
        export XDG_CURRENT_DESKTOP=tomoe
        export XDG_SESSION_TYPE=wayland
        export NIXOS_OZONE_WL=1
        export QT_QPA_PLATFORM=wayland
        export ELECTRON_OZONE_PLATFORM_HINT=wayland
        export GDK_BACKEND=wayland
        export SDL_VIDEODRIVER=wayland,x11
        export CLUTTER_BACKEND=wayland
        export XCURSOR_THEME=${flakeInputs.cursors.packages."${sys}".deepin-dark.xcursorThemeName}
        export XCURSOR_SIZE=24
        case ":''${XDG_DATA_DIRS:-}:" in
          *":/run/current-system/sw/share:"*) ;;
          *) export XDG_DATA_DIRS="/run/current-system/sw/share''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}" ;;
        esac
        export TERMINAL=${config.user.defaults.terminal}

        export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
        [ -d "$XDG_RUNTIME_DIR" ] || {
          echo "tomoe-session: $XDG_RUNTIME_DIR missing (xdg-runtime-dir task failed?)" >&2
          exit 1
        }

        ${lib.optionalString config.hardware.nvidia.enable ''
          export WLR_NO_HARDWARE_CURSORS=1
          export LIBVA_DRIVER_NAME=nvidia
          export __GL_SYNC_TO_VBLANK=0
          export __GL_VRR_ALLOWED=1
          export __GL_MaxFramesAllowed=1
          export __GL_YIELD=usleep
          export CUDA_CACHE_PATH="$HOME/.cache/nv"
          export CUDA_DISABLE_PERF_BOOST=1
          export NVIDIA_DRIVER_CAPABILITIES=all
        ''}
        cd "$HOME"
        policy="$HOME/.config/tomoe/init.lisp"
        ${pkgs.coreutils}/bin/mkdir -p "$HOME/.config/tomoe"
        ${pkgs.coreutils}/bin/install -m 0644 ${starterPolicy} "$policy"
        exec ${pkgs.dbus}/bin/dbus-run-session -- ${pkgs.writeShellScript "tomoe-session-inner" ''
          ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 &
          exec ${lib.getExe tomoePkg} --backend drm "$@"
        ''} "$@"
      '')
      pkgs.monstar
      pkgs.grim
      pkgs.slurp
      pkgs.wl-clipboard-rs
      pkgs.jq
      pkgs.swaybg
      pkgs.xwayland-satellite
      pkgs.ripgrep
      pkgs.fd
    ];
  };

  security.pam.services.login.text = lib.mkForce ''
    account required pam_unix.so # unix (order 10900)

    auth optional pam_unix.so likeauth nullok # unix-early (order 11500)
    auth sufficient pam_unix.so likeauth nullok try_first_pass # unix (order 12800)
    auth required pam_deny.so # deny (order 13600)

    password sufficient pam_unix.so nullok yescrypt # unix (order 10200)

    session required pam_env.so conffile=/etc/security/pam_env.conf readenv=0 # env
    session required pam_unix.so # unix
    session required pam_loginuid.so # loginuid
    session required pam_limits.so conf=/etc/security/limits.conf
    ${lib.optionalString config.services.elogind.enable "session optional ${config.services.elogind.package}/lib/security/pam_elogind.so"}
    session required ${config.security.pam.package}/lib/security/pam_lastlog.so silent # lastlog
  '';

  security.pam.services.sshd.text = lib.mkForce ''
    account required pam_unix.so debug # unix (order 10900)

    auth sufficient pam_unix.so likeauth try_first_pass debug # unix (order 11500)
    auth required pam_deny.so debug # deny (order 12300)

    password sufficient pam_unix.so nullok yescrypt debug # unix (order 10200)

    session required pam_env.so debug conffile=/etc/security/pam_env.conf readenv=0 # env
    session required pam_unix.so debug # unix
    session required pam_loginuid.so debug # loginuid
    session required pam_limits.so
    ${lib.optionalString config.services.elogind.enable "session optional ${config.services.elogind.package}/lib/security/pam_elogind.so"}
  '';

  fonts.packages = [
    flakeInputs.fonts.packages."${sys}".default
    pkgs.noto-fonts-cjk-sans
    pkgs.noto-fonts-color-emoji
  ];
}

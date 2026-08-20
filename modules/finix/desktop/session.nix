# Phase-2b: the graphical session — tomoe (smithay compositor from
# flakeInputs.tomoe) + session shim + fonts + daily-driver shell bits.
# Packages cross the module-universe split freely (same pattern as `pi`);
# only NixOS MODULES are unimportable. The shim mirrors
# modules/desktop/session/ui/tomoe/config.nix (NixOS universe) — keep in
# lockstep by hand.
#
# Deferred to 2c: pipewire (no upstream module — audio is absent until we
# hand-roll a finit service), Steam. Portals now use finix's upstream xdg
# module; the per-desktop config remains a local stand-in for its missing
# xdg.portal.config option.
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

  # force_server_side_decorations landed upstream in tomoe.
  tomoePkg = flakeInputs.tomoe.packages."${sys}".default;
in {
  # seatd: upstream defaults the service to runlevels [34], but finix
  # boots into runlevel 2 — the service is never eligible and initctl
  # shows a misleading "halted (exit 0)". Its command (`-n %n` + notify:s6)
  # is fine — udevd uses the same pattern. UPSTREAM GAP: seatd runlevels
  # vs default runlevel.
  finit.services.seatd.runlevels = lib.mkForce "234";

  # finix has the portal package/portal-linking module but not NixOS's
  # per-desktop xdg.portal.config generator; install the tomoe policy here
  # until the upstream option lands (the compositor's own shipped file uses
  # default=* while retaining this same ScreenCast mapping).
  xdg.portal = {
    enable = true;
    portals = [pkgs.xdg-desktop-portal-gtk tomoePkg];
  };

  # The picker moved into the compositor (require("screencast") in init.lua),
  # so no TOMOE_PORTAL_CHOOSER wrapper is exported here.
  environment.etc."xdg/xdg-desktop-portal/tomoe-portals.conf".text = ''
    [preferred]
    default=gtk
    org.freedesktop.impl.portal.ScreenCast=tomoe
  '';

  # seatd-only hosts need one stable runtime-dir owner. Elogind hosts create it
  # through pam_elogind instead, avoiding two owners racing login teardown.
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
        # Mirror of the NixOS tomoe-session shim; session env stays scoped to
        # the compositor process, never global.
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
        # Portals + .desktop discovery: dbus activation and app launchers scan
        # XDG_DATA_DIRS; the system profile carries dbus-1 service files for
        # xdg-desktop-portal{,-gtk} and tomoe's own portal. Deduped — a re-exec
        # (or a profile that already prepends) must not stack duplicates.
        case ":''${XDG_DATA_DIRS:-}:" in
          *":/run/current-system/sw/share:"*) ;;
          *) export XDG_DATA_DIRS="/run/current-system/sw/share''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}" ;;
        esac
        # Launcher parity: tui-launcher falls back to alacritty (not installed)
        # when TERMINAL is unset, so Terminal=true .desktop entries and the
        # command provider die silently. modules/core/user/defaults.nix now puts
        # TERMINAL in environment.sessionVariables (/etc/profile.d), which covers
        # login shells; this stays as the belt-and-braces path for a session
        # exec'd from something that never read /etc/profile.
        export TERMINAL=foot

        # No logind: guarantee the runtime dir even if the profile.d hook was
        # skipped (e.g. exec'd from a bare shell).
        export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
        [ -d "$XDG_RUNTIME_DIR" ] || {
          echo "tomoe-session: $XDG_RUNTIME_DIR missing (xdg-runtime-dir task failed?)" >&2
          exit 1
        }

        ${lib.optionalString config.hardware.nvidia.enable ''
          export WLR_NO_HARDWARE_CURSORS=1
          export LIBVA_DRIVER_NAME=nvidia
          # environment.sessionVariables parity (NixOS nvidia.nix).
          export __GL_SYNC_TO_VBLANK=0
          export __GL_VRR_ALLOWED=1
          export __GL_MaxFramesAllowed=1
          export __GL_YIELD=usleep
          export CUDA_CACHE_PATH="$HOME/.cache/nv"
          export CUDA_DISABLE_PERF_BOOST=1
          export NVIDIA_DRIVER_CAPABILITIES=all
        ''}
        # No GBM_BACKEND / __EGL_VENDOR_LIBRARY_FILENAMES / __GLX_VENDOR_LIBRARY_NAME
        # — see the NixOS shim: forcing the NVIDIA EGL vendor hides Mesa's
        # EGL_EXT_device_query and smithay then finds no renderer at all.
        cd "$HOME"
        # No logind → no per-login session bus; dbus-run-session gives the
        # compositor AND everything it spawns one session bus, on which the
        # portals dbus-activate. The polkit agent must live on that same bus,
        # so it starts inside the wrapper (NixOS ran it as a systemd user
        # service on graphical-session.target).
        # xwayland-satellite (started by tomoe's process.once) claims :0 —
        # export it so terminals + steam inherit X availability.
        export DISPLAY=:0
        exec ${pkgs.dbus}/bin/dbus-run-session -- ${pkgs.writeShellScript "tomoe-session-inner" ''
          ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 &
          exec ${lib.getExe tomoePkg} --backend tty "$@"
        ''} "$@"
      '')
      # Session companions (NixOS shim parity).
      pkgs.foot
      pkgs.grim
      pkgs.slurp
      pkgs.wl-clipboard-rs
      pkgs.jq
      pkgs.swaybg
      pkgs.xwayland-satellite
      # Daily-driver shell: rush. finix/common.nix sets it as the login shell;
      # modules/shell/rush/config.nix generates ~/.config/rush/{profile,config}.rush
      # onto persisted /home. rush itself comes from that module's systemPackages
      # (or common.nix on the server), bash from finix's programs.bash (still
      # /bin/sh). Autosuggestions/history-search/completions are rush builtins,
      # so carapace and fzf key-bindings are gone.
      pkgs.ripgrep
      pkgs.fd
    ];
  };

  # pam_rundir — injected into every login path by upstream whenever
  # services.seatd.enable is set (shadow + openssh modules, no opt-out
  # knob) — refcounts sessions in /run/user/.<uid> and DELETES
  # /run/user/<uid> on the last close_session. Incompatible with this
  # host's model: pipewire/wireplumber/pipewire-pulse are finit SYSTEM
  # services that outlive logins, and the dir is boot-created above.
  # Observed 2026-07-18: tty logout (or last ssh drop) removed the dir
  # under the daemons; tomoe-session then failed its runtime-dir check.
  # One owner only: the finit task. Force the upstream PAM texts minus
  # the pam_rundir line (verbatim copies otherwise — keep in lockstep
  # with upstream shadow/openssh modules by hand).
  # UPSTREAM GAP: seatd should not imply pam_rundir unconditionally.
  security.pam.services.login.text = lib.mkForce ''
    # Account management.
    account required pam_unix.so # unix (order 10900)

    # Authentication management.
    auth optional pam_unix.so likeauth nullok # unix-early (order 11500)
    auth sufficient pam_unix.so likeauth nullok try_first_pass # unix (order 12800)
    auth required pam_deny.so # deny (order 13600)

    # Password management.
    password sufficient pam_unix.so nullok yescrypt # unix (order 10200)

    # Session management.
    session required pam_env.so conffile=/etc/security/pam_env.conf readenv=0 # env
    session required pam_unix.so # unix
    session required pam_loginuid.so # loginuid
    session required pam_limits.so conf=/etc/security/limits.conf
    ${lib.optionalString config.services.elogind.enable "session optional ${config.services.elogind.package}/lib/security/pam_elogind.so"}
    session required ${config.security.pam.package}/lib/security/pam_lastlog.so silent # lastlog
  '';

  security.pam.services.sshd.text = lib.mkForce ''
    # Account management.
    account required pam_unix.so debug # unix (order 10900)

    # Authentication management.
    auth sufficient pam_unix.so likeauth try_first_pass debug # unix (order 11500)
    auth required pam_deny.so debug # deny (order 12300)

    # Password management.
    password sufficient pam_unix.so nullok yescrypt debug # unix (order 10200)

    # Session management.
    session required pam_env.so debug conffile=/etc/security/pam_env.conf readenv=0 # env
    session required pam_unix.so debug # unix
    session required pam_loginuid.so debug # loginuid
    session required pam_limits.so
    ${lib.optionalString config.services.elogind.enable "session optional ${config.services.elogind.package}/lib/security/pam_elogind.so"}
  '';

  # Automatic DISPLAY everywhere a login shell starts (TTY/ssh), not just
  # under the compositor: in-session processes inherit the shim's export;
  # this covers the rest by probing for a live X socket. Dynamic — no
  # hardcoded :0 assumption if satellite ever lands elsewhere.

  # Fonts: same trio as the NixOS ui/fonts.nix defaults. foot picks the
  # family from the persisted ~/.config/foot config; fontconfig just has
  # to be able to resolve it.
  fonts = {
    fontconfig.enable = true;
    packages = [
      flakeInputs.fonts.packages."${sys}".default
      pkgs.noto-fonts-cjk-sans
      pkgs.noto-fonts-color-emoji
    ];
  };

  # Login shell comes from finix/common.nix (rush) — no override.
}

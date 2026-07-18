# Phase-2b: the graphical session — tomoe (smithay compositor from
# flakeInputs.tomoe) + session shim + fonts + daily-driver shell bits.
# Packages cross the module-universe split freely (same pattern as `pi`);
# only NixOS MODULES are unimportable. The shim mirrors
# modules/desktop/session/ui/tomoe/config.nix (NixOS universe) — keep in
# lockstep by hand.
#
# Deferred to 2c: pipewire (no upstream module — audio is absent until we
# hand-roll a finit service), xdg portals + TOMOE_PORTAL_CHOOSER (need a
# session dbus + elogind PAM story), Steam.
{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  sys = pkgs.stdenv.hostPlatform.system;
  tomoePkg = flakeInputs.tomoe.packages.${sys}.default;
  cursorPkg = flakeInputs.cursors.packages.${sys}.deepin-dark;
  mainFont = flakeInputs.fonts.packages.${sys}.default;

  # Screencast source picker for xdg-desktop-portal-tomoe — verbatim port
  # of the NixOS shim's chooser (dmenu contract: candidates on stdin,
  # choice on stdout, non-zero exit = cancel; portal hands us pipes, so
  # shuttle via tmpdir and run fzf in a floating foot window).
  portalChooser = pkgs.writeShellScript "portal-chooser" ''
    set -eu
    dir=$(${pkgs.coreutils}/bin/mktemp -d)
    trap '${pkgs.coreutils}/bin/rm -rf "$dir"' EXIT
    ${pkgs.coreutils}/bin/cat > "$dir/in"
    ${lib.getExe pkgs.foot} --app-id=launcher -e ${pkgs.runtimeShell} -c \
      "${lib.getExe pkgs.fzf} --prompt 'cast: ' < '$dir/in' > '$dir/out'" || true
    [ -s "$dir/out" ] || exit 1
    ${pkgs.coreutils}/bin/cat "$dir/out"
  '';

  tomoeSession = pkgs.writeShellScriptBin "tomoe-session" ''
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
    export XCURSOR_THEME=${cursorPkg.xcursorThemeName}
    export XCURSOR_SIZE=24
    # Portals + .desktop discovery: dbus activation and app launchers scan
    # XDG_DATA_DIRS; the system profile carries dbus-1 service files for
    # xdg-desktop-portal{,-gtk} and tomoe's own portal.
    export XDG_DATA_DIRS="/run/current-system/sw/share''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
    export TOMOE_PORTAL_CHOOSER="''${TOMOE_PORTAL_CHOOSER:-${portalChooser}}"

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
  '';
in {
  # seatd: upstream defaults the service to runlevels [34], but finix
  # boots into runlevel 2 — the service is never eligible and initctl
  # shows a misleading "halted (exit 0)". Its command (`-n %n` + notify:s6)
  # is fine — udevd uses the same pattern. UPSTREAM GAP: seatd runlevels
  # vs default runlevel.
  finit.services.seatd.runlevels = lib.mkForce "234";

  # XDG_RUNTIME_DIR without logind: tmpfs-backed /run survives nothing,
  # so create the dir every boot; profile.d exports it for login shells.
  # Replace with elogind + pam_elogind when portals force the issue (2c).
  finit.tasks.xdg-runtime-dir = {
    description = "runtime dir for y0usaf";
    command = pkgs.writeShellScript "xdg-runtime-dir" ''
      export PATH=${lib.makeBinPath [pkgs.coreutils]}
      install -d -m 0700 -o y0usaf -g users /run/user/1001
    '';
    log = true;
  };
  environment.etc."profile.d/xdg-runtime-dir.sh".text = ''
    if [ -z "''${XDG_RUNTIME_DIR:-}" ]; then
      export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    fi
  '';

  # Fonts: same trio as the NixOS ui/fonts.nix defaults. foot picks the
  # family from the persisted ~/.config/foot config; fontconfig just has
  # to be able to resolve it.
  fonts = {
    fontconfig.enable = true;
    packages = [
      mainFont
      pkgs.noto-fonts-cjk-sans
      pkgs.noto-fonts-color-emoji
    ];
  };

  environment.systemPackages = [
    tomoePkg
    tomoeSession
    # Session companions (NixOS shim parity).
    pkgs.foot
    pkgs.grim
    pkgs.slurp
    pkgs.wl-clipboard-rs
    pkgs.jq
    pkgs.swaybg
    pkgs.xwayland-satellite
    # Portals (2c): tomoe ships its own portal backend + config in its
    # package; gtk covers file pickers.
    pkgs.xdg-desktop-portal
    pkgs.xdg-desktop-portal-gtk
    # Daily-driver shell: config.nu/env.nu already live on persisted
    # /home (generated by the NixOS side). Login shell stays bash for
    # rescue-simplicity — run `nu`, or flip users.users.y0usaf.shell
    # once nushell has proven itself under finix.
    pkgs.nushell
    pkgs.fzf
    pkgs.ripgrep
    pkgs.fd
  ];
}

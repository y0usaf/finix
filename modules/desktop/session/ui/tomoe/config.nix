{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (config.lib.generators) toLua;
  nvidiaSessionEnvironment = enabled:
    lib.optionalString enabled ''
      export WLR_NO_HARDWARE_CURSORS=1
      export LIBVA_DRIVER_NAME=nvidia
    '';
  hostExtraConfig = extra: lib.optionalString (extra != "") "\n-- ─── host extraConfig ────────────────────────────────────────────────────────\n${extra}\n";

  # force_server_side_decorations landed upstream in tomoe (8e0bd50); the local
  # patch that used to carry it is gone — the packaged default has it now.
  tomoePkg = flakeInputs.tomoe.packages."${pkgs.stdenv.hostPlatform.system}".default;
  # The old Rust+Lua compositor, from the separate tomoe-lua input pin. Kept
  # out of the let's single tomoePkg so the two can never be conflated.
  tomoeLuaPkg = flakeInputs.tomoe-lua.packages."${pkgs.stdenv.hostPlatform.system}".default;
  inherit (config.user.ui.tomoe) bar;
  # tomoe only fingerprints init.lua for config reloads (crates/tomoe/src/main.rs
  # polls its canonical path + mtime every 500ms; state.rs:69-80). The
  # shell/*.lua files next to it are pulled in with dofile, so changing one of
  # them alone would deploy fine and never reload — the running VM keeps the old
  # bar. Stamping their content hash into init.lua makes its store path change
  # with them, so the poll sees a new canonical path and reloads.
  shellAssetHash = builtins.hashString "sha256" (lib.concatStrings [
    (builtins.readFile ./lua/bar_overlay.lua)
    (builtins.readFile ./lua/sysinfo.lua)
    (builtins.readFile ./lua/wallust.lua)
    (builtins.toJSON bar)
  ]);
  # One file per user.ui.tomoe.layout value.
  layoutChunks = {
    deck = ./lua/layout-deck.lua;
    sway = ./lua/layout-sway.lua;
  };
  # Everything init.lua reads from Nix, serialized once as the `nix` table
  # ahead of the hand-written chunks in ./lua. The chunks are concatenated
  # into one Lua chunk, so their locals (floating, wm, sh_quote) stay shared.
  nixValues = {
    inherit (config.user.ui.tomoe) displays;
    nvidia = config.hardware.nvidia.enable;
    inherit (config.user.defaults) terminal launcher;
    wallpaper_dir = config.user.paths.wallpapers.static.path;
    bin.xwayland_satellite = lib.getExe pkgs.xwayland-satellite;
    # BarOverlay.open() options for the in-VM bar (deployed next to init.lua
    # by shell.nix); null when the bar is off. font_family is assigned in
    # Lua after fc-match resolution.
    bar =
      if bar.enable
      then {
        inherit (bar) modules edges indent exclusive;
        bongo_cat = {
          inherit (bar.bongo-cat) enable height;
          asset_dir = ./assets/bongo-cat;
          name = "bongo-cat";
          margin_bottom = bar.bongo-cat.margin-bottom;
          x_offset = bar.bongo-cat.x-offset;
          keypress_duration = bar.bongo-cat.keypress-duration;
          layer = "overlay";
        };
      }
      else null;
  };
in {
  config = lib.mkIf config.user.ui.tomoe.enable {
    environment.systemPackages =
      [
        tomoePkg
        pkgs.grim
        pkgs.slurp
        pkgs.wl-clipboard-rs
        pkgs.jq
        pkgs.swaybg
        pkgs.xwayland-satellite
      ]
      ++ lib.optional config.user.ui.tomoeLua.enable
      # Manual fallback session: the OLD Rust+Lua tomoe (flake input
      # `tomoe-lua`), for when the primary Lisp compositor misbehaves. The
      # name is deliberately distinct — the bare `tomoe-session` is the Lisp
      # shim, and finix's env builder sets ignoreCollisions = true, so a
      # same-named shim here would be silently dropped.
      # The compositor package itself is NOT added to systemPackages: that
      # would put a second derivation named `tomoe` (also shipping bin/tomoe)
      # on PATH, which the same collision setting would resolve silently and
      # could change which compositor the PRIMARY session runs.
      (pkgs.writeShellScriptBin "tomoe-lua-session" ''
        export XDG_CURRENT_DESKTOP=tomoe
        export XDG_SESSION_TYPE=wayland
        export NIXOS_OZONE_WL=1
        export QT_QPA_PLATFORM=wayland
        export ELECTRON_OZONE_PLATFORM_HINT=wayland
        export GDK_BACKEND=wayland
        export SDL_VIDEODRIVER=wayland,x11
        export CLUTTER_BACKEND=wayland
        export XCURSOR_THEME=${config.user.ui.cursor.package.xcursorThemeName}
        export XCURSOR_SIZE=${toString config.user.appearance.xcursorSize}

        ${nvidiaSessionEnvironment config.hardware.nvidia.enable}
        # No GBM_BACKEND / __EGL_VENDOR_LIBRARY_FILENAMES / __GLX_VENDOR_LIBRARY_NAME
        # here: forcing the NVIDIA-only EGL vendor hides Mesa's EGL_EXT_device_query
        # from the glvnd client-extension union, which smithay requires to probe the
        # render device — tomoe then finds no renderer on ANY GPU and comes up with
        # zero outputs (black screen). run-tty.sh never set these and works.

        # No logind on finix (seatd-based): guarantee the runtime dir even if
        # the profile.d hook was skipped (e.g. exec'd from a bare shell).
        export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
        [ -d "$XDG_RUNTIME_DIR" ] || {
          echo "tomoe-lua-session: $XDG_RUNTIME_DIR missing (xdg-runtime-dir task failed?)" >&2
          exit 1
        }

        cd "$HOME"
        # No logind → no per-login session bus; dbus-run-session gives the
        # compositor AND everything it spawns one session bus, on which the
        # portals dbus-activate. The polkit agent must live on that same bus,
        # so it starts inside the wrapper. Mirrors the Lisp shim in
        # modules/finix/desktop/session.nix.
        exec ${pkgs.dbus}/bin/dbus-run-session -- ${pkgs.writeShellScript "tomoe-lua-session-inner" ''
          ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 &
          exec ${lib.getExe tomoeLuaPkg} --backend tty "$@"
        ''} "$@"
      '');

    manzil.users."${config.user.name}".files.".config/tomoe/init.lua".text =
      ''
        -- Generated by ~/finix (modules/desktop/session/ui/tomoe/config.nix).
        -- Shell asset fingerprint: ${shellAssetHash}
        -- tomoe only fingerprints THIS file for reloads (main.rs polls its
        -- canonical path + mtime every 500ms). The shell/*.lua files are
        -- pulled in with dofile, so editing them alone would never trigger a
        -- reload. Stamping their hash here changes init.lua's store path
        -- whenever they change, which makes the poll notice.
        local nix = ${toLua nixValues}

      ''
      + lib.concatMapStrings builtins.readFile [
        ./lua/session.lua
        layoutChunks.${config.user.ui.tomoe.layout}
        ./lua/binds.lua
      ]
      + hostExtraConfig config.user.ui.tomoe.extraConfig;
  };
}

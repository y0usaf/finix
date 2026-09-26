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

  tomoePkg = flakeInputs.tomoe.packages."${pkgs.stdenv.hostPlatform.system}".default;
  tomoeLuaPkg = flakeInputs.tomoe-lua.packages."${pkgs.stdenv.hostPlatform.system}".default;
  inherit (config.user.ui.tomoe) bar;
  shellAssetHash = builtins.hashString "sha256" (lib.concatStrings [
    (builtins.readFile ./lua/bar_overlay.lua)
    (builtins.readFile ./lua/sysinfo.lua)
    (builtins.readFile ./lua/wallust.lua)
    (builtins.toJSON bar)
  ]);
  layoutChunks = {
    deck = ./lua/layout-deck.lua;
    sway = ./lua/layout-sway.lua;
  };
  nixValues = {
    inherit (config.user.ui.tomoe) displays;
    nvidia = config.hardware.nvidia.enable;
    inherit (config.user.defaults) terminal launcher;
    wallpaper_dir = config.user.paths.wallpapers.static.path;
    bin.xwayland_satellite = lib.getExe pkgs.xwayland-satellite;
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

        export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
        [ -d "$XDG_RUNTIME_DIR" ] || {
          echo "tomoe-lua-session: $XDG_RUNTIME_DIR missing (xdg-runtime-dir task failed?)" >&2
          exit 1
        }

        cd "$HOME"
        exec ${pkgs.dbus}/bin/dbus-run-session -- ${pkgs.writeShellScript "tomoe-lua-session-inner" ''
          ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 &
          exec ${lib.getExe tomoeLuaPkg} --backend tty "$@"
        ''} "$@"
      '');

    manzil.users."${config.user.name}".files.".config/tomoe/init.lua".text =
      ''
        -- Shell asset fingerprint: ${shellAssetHash}
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

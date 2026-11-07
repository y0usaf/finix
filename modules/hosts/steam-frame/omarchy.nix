{
  lib,
  pkgs,
  frameSession,
  generators,
  ...
}: let
  width = 1920;
  height = 1080;
  mode = "${toString width}x${toString height}@60";
  scale = "1.5";
  overlayMetres = "2.67";
  themes = [
    "tokyo-night"
    "catppuccin"
    "rose-pine"
    "kanagawa"
  ];

  src = pkgs.fetchFromGitHub {
    owner = "basecamp";
    repo = "omarchy";
    rev = "c668141e9c42b13c80c9ca4ea108e11708c5e8a5";
    hash = "sha256-nstxM+CP6al2I4N1LAKdYBvJ4tytD1m8jssiCD7PXTY=";
  };

  omarchy = pkgs.runCommand "omarchy-4.0.4" {} ''
    cp -r ${src} $out
    chmod -R u+w $out
    rm -rf $out/manual $out/test $out/docs $out/agents
    find $out/themes -mindepth 1 -maxdepth 1 ${
      lib.concatMapStringsSep " " (t: "! -name ${t}") themes
    } -exec rm -r {} +
    patchShebangs $out/bin
  '';

  aquamarine = pkgs.aquamarine.overrideAttrs (old: {
    patches =
      (old.patches or [])
      ++ [
        (generators.sourceFile "aquamarine-gamescope.patch" (generators.patch.render (({
            add,
            del,
            git,
            section,
            ...
          }: [
            (git "src/backend/Wayland.cpp" "8905adc..c6de7cc 100644" [
              (section 122 "bool Aquamarine::CWaylandBackend::start() {" [
                "            initSeat();"
                "        } else if (NAME == \"xdg_wm_base\") {"
                "            TRACE(backend->log(AQ_LOG_TRACE, std::format(\"  > binding to global: {} (version {}) with id {}\", name, 6, id)));"
                (del "            waylandState.xdg = makeShared<CCXdgWmBase>((wl_proxy*)wl_registry_bind((wl_registry*)waylandState.registry->resource(), id, &xdg_wm_base_interface, 6));")
                (add "            waylandState.xdg = makeShared<CCXdgWmBase>((wl_proxy*)wl_registry_bind((wl_registry*)waylandState.registry->resource(), id, &xdg_wm_base_interface, std::min(version, 6u)));")
                "            initShell();"
                "        } else if (NAME == \"wl_compositor\") {"
                "            TRACE(backend->log(AQ_LOG_TRACE, std::format(\"  > binding to global: {} (version {}) with id {}\", name, 6, id)));"
                (del "            waylandState.compositor = makeShared<CCWlCompositor>((wl_proxy*)wl_registry_bind((wl_registry*)waylandState.registry->resource(), id, &wl_compositor_interface, 6));")
                (add "            waylandState.compositor = makeShared<CCWlCompositor>((wl_proxy*)wl_registry_bind((wl_registry*)waylandState.registry->resource(), id, &wl_compositor_interface, std::min(version, 6u)));")
                "        } else if (NAME == \"wl_shm\") {"
                "            TRACE(backend->log(AQ_LOG_TRACE, std::format(\"  > binding to global: {} (version {}) with id {}\", name, 1, id)));"
                "            waylandState.shm = makeShared<CCWlShm>((wl_proxy*)wl_registry_bind((wl_registry*)waylandState.registry->resource(), id, &wl_shm_interface, 1));"
              ])
              (section 541 "Aquamarine::CWaylandOutput::CWaylandOutput(const std::string& name_, Hyprutils::" [
                "    waylandState.xdgToplevel->setConfigure([this](CCXdgToplevel* r, int32_t w, int32_t h, wl_array* arr) {"
                "        backend->backend->log(AQ_LOG_DEBUG, std::format(\"Output {}: configure toplevel with {}x{}\", name, w, h));"
                "        if (w == 0 || h == 0) {"
                (del "            backend->backend->log(AQ_LOG_DEBUG, std::format(\"Output {}: w/h is 0, sending default hardcoded 1280x720\", name));")
                (del "            w = 1280;")
                (del "            h = 720;")
                (add "            if (waylandState.surfaceSize.x > 0 && waylandState.surfaceSize.y > 0) {")
                (add "                w = waylandState.surfaceSize.x;")
                (add "                h = waylandState.surfaceSize.y;")
                (add "            } else {")
                (add "                backend->backend->log(AQ_LOG_DEBUG, std::format(\"Output {}: w/h is 0, sending default hardcoded 1280x720\", name));")
                (add "                w = 1280;")
                (add "                h = 720;")
                (add "            }")
                "        }"
                "        events.state.emit(SStateEvent{.size = {w, h}});"
                "        // Kick off the first frame synchronously: the consumer expects events.frame in"
              ])
              (section 567 "Aquamarine::CWaylandOutput::CWaylandOutput(const std::string& name_, Hyprutils::" [
                ""
                "    inputRegion->sendDestroy();"
                ""
                (add "    wl_display_flush(backend->waylandState.display);")
                (add "")
                "    backend->backend->log(AQ_LOG_DEBUG, std::format(\"Output {}: initialized\", name));"
                "}"
                ""
              ])
            ])
          ])
          generators.patch)))
      ];
  });

  uwsmApp = pkgs.writeShellScriptBin "uwsm-app" ''
    [ "$1" = -- ] && shift
    exec ${pkgs.util-linux}/bin/setsid -f "$@"
  '';

  tools = [
    pkgs.coreutils
    pkgs.findutils
    pkgs.gnugrep
    pkgs.gnused
    pkgs.gawk
    pkgs.gnutar
    pkgs.gzip
    pkgs.procps
    pkgs.util-linux
    pkgs.systemd
    pkgs.jq
    pkgs.gum
    pkgs.fzf
    pkgs.socat
    pkgs.inotify-tools
    pkgs.curl
    pkgs.imagemagick
    pkgs.libnotify
    pkgs.fontconfig
    pkgs.wl-clipboard
    pkgs.wtype
    pkgs.grim
    pkgs.slurp
    pkgs.brightnessctl
    pkgs.pamixer
    pkgs.networkmanager
    pkgs.xdg-utils
    pkgs.xdg-terminal-exec
    pkgs.foot
    pkgs.hyprland
    pkgs.quickshell
  ];

  fontsConf = pkgs.writeText "fonts.conf" ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <include>${
      pkgs.makeFontsConf {
        fontDirectories = [
          pkgs.jetbrains-mono
          pkgs.nerd-fonts.symbols-only
          pkgs.liberation_ttf
        ];
      }
    }</include>
      <include>${omarchy}/default/fontconfig/conf.avail/50-omarchy.conf</include>
      <alias binding="same">
        <family>JetBrainsMono Nerd Font</family>
        <prefer>
          <family>JetBrains Mono</family>
          <family>Symbols Nerd Font</family>
        </prefer>
      </alias>
    </fontconfig>
  '';

  session = pkgs.writeShellScript "omarchy-session" ''
    export OMARCHY_PATH=${omarchy}
    export OMARCHY_MODE=${mode}
    export OMARCHY_SCALE=${scale}
    export PATH=${omarchy}/bin:${uwsmApp}/bin:${lib.makeBinPath tools}:$PATH
    export XDG_DATA_DIRS=${omarchy}/default:${pkgs.foot}/share:''${XDG_DATA_DIRS:-/usr/share}
    export FONTCONFIG_FILE=${fontsConf}
    export XDG_CURRENT_DESKTOP=Hyprland
    export ENABLE_GAMESCOPE_WSI=0
    export LIBSEAT_BACKEND=seatd
    export LD_LIBRARY_PATH=${aquamarine}/lib
    unset DISPLAY
    [ -e "$HOME/.local/state/omarchy/current/theme" ] || OMARCHY_THEME_HEADLESS=1 omarchy-theme-set "Tokyo Night"
    exec ${pkgs.hyprland}/bin/Hyprland -c ${./omarchy/hyprland.lua}
  '';

  overlay = lib.concatStringsSep " " [
    "gamescope"
    "--backend openvr"
    "--expose-wayland"
    "-W ${toString width}"
    "-H ${toString height}"
    "--vr-overlay-key valve.omarchy.desktop"
    "--vr-overlay-explicit-name Omarchy"
    "--vr-overlay-icon ${omarchy}/icon.png"
    "--vr-overlay-physical-width ${overlayMetres}"
    "--vr-overlay-show-immediately"
    "--vr-overlay-enable-control-bar"
    "--vr-overlay-enable-control-bar-keyboard"
    "--vr-overlay-enable-control-bar-close"
    "--vr-overlay-enable-click-stabilization"
    "-- ${session}"
  ];
in {
  system.build.omarchySession = session;

  systemd.user.services.omarchy = {
    description = "Omarchy desktop overlay";
    bindsTo = ["steamvr.service"];
    after = ["steamvr.service"];
    environment = frameSession.valveMesaEnv;
    serviceConfig = {
      Slice = "session.slice";
      EnvironmentFile = frameSession.mesavars;
      ExecStart = frameSession.inFhs overlay;
      ExecStopPost = "${pkgs.runtimeShell} -c 'cd %t && rm -rf hypr quickshell omarchy-*'";
      TimeoutStopSec = 10;
    };
  };
}

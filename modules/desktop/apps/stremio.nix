{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.programs.stremio = {
    enable = lib.mkEnableOption "Stremio media center";
  };
  config = lib.mkIf config.user.programs.stremio.enable {
    environment.systemPackages = [
      (pkgs.rustPlatform.buildRustPackage (finalAttrs: {
        pname = "stremio-linux-shell";
        version = "1.1.4-unstable-3826d3c";

        src = pkgs.fetchFromGitHub {
          owner = "Stremio";
          repo = "stremio-linux-shell";
          rev = "3826d3c9a97e83d218b6bf87321f2817065cef46";
          hash = "sha256-Y5BkMviHM1+DcwUrrv4eqCLjawKfA4ZaohjgpFQjjFk=";
        };

        # Current main: WebKitGTK-based, GTK4/libadwaita. No CEF, all deps on crates.io.
        # Lock file vendored into this repo (copied from src). Pointing lockFile at
        # "${src}/Cargo.lock" is IFD: nix must download the GitHub tarball DURING
        # evaluation, stalling every eval on network. Refresh the copy when rev bumps.
        cargoLock = {
          lockFile = ./stremio-Cargo.lock;
        };

        postPatch = ''
          # Route mpv through pipewire-pulse so Stremio appears as shareable audio
          # (Vesktop/venmic cannot select native PipeWire mpv streams).
          substituteInPlace src/app/video/imp.rs \
            --replace-fail 'init.set_property("vo", "libmpv")?;' \
              'init.set_property("vo", "libmpv")?; init.set_property("ao", "pulse")?;'

          # No decoration patches needed: with --no-window-decorations parsed
          # correctly (single flag, see shim below), upstream realize() hides the
          # AdwHeaderBar and drops the csd class itself. set_titlebar() must NOT
          # be patched in — it g_error-aborts on AdwApplicationWindow.

          # build.rs writes GLib schemas into dirs::data_dir() (=HOME/.local/share);
          # the nix builder HOME is unwritable; export persists into the build phase
          export HOME=/build
        '';

        nativeBuildInputs = [
          pkgs.wrapGAppsHook4
          pkgs.makeBinaryWrapper
          pkgs.pkg-config
          pkgs.gettext # msgfmt for build.rs po -> mo
          pkgs.glib.bin # glib-compile-schemas
        ];

        buildInputs = [
          pkgs.gtk4
          pkgs.libadwaita
          pkgs.webkitgtk_6_0 # WebKitGTK 6.0 (2.52), matches crate webkit6 v2_52
          pkgs.glib-networking # TLS/proxy for the webview
          pkgs.libepoxy # dlopen'd at runtime
          pkgs.mpv # libmpv
        ];

        postInstall = ''
          mkdir -p $out/share/applications $out/share/icons/hicolor/scalable/apps \
                   $out/share/glib-2.0/schemas $out/share/stremio
          cp data/com.stremio.Stremio.desktop $out/share/applications/
          cp data/icons/com.stremio.Stremio.svg $out/share/icons/hicolor/scalable/apps/
          cp data/com.stremio.Stremio.gschema.xml $out/share/glib-2.0/schemas/
          cp data/server.js $out/share/stremio/server.js

          # v1.1.4 hard-requires the compiled GSettings schema (app aborts otherwise);
          # wrapGAppsHook relocates it to share/gsettings-schemas but doesn't compile it here.
          glib-compile-schemas "$out/share/glib-2.0/schemas"

          # upstream data/stremio.sh: force GSK OpenGL renderer on NVIDIA.
          # Shim resolves its sibling binary relative to its own location
          # (wrapGAppsHook wraps both binaries after us).
          cat > $out/bin/stremio <<'SH'
          #!/bin/sh
          [ -e /dev/nvidia0 ] && export GSK_RENDERER=opengl
          # --no-window-decorations lives HERE, not in gappsWrapperArgs: the hook
          # wraps BOTH this shim and stremio-linux-shell, so add-flags delivered
          # the flag twice; clap SetTrue + ignore_errors(true) silently resolves
          # a duplicated flag to FALSE (verified against clap 4.6.1).
          exec "$(dirname "$0")/stremio-linux-shell" --no-window-decorations "$@"
          SH
          chmod +x $out/bin/stremio
        '';

        preFixup = ''
          gappsWrapperArgs+=(
            # stremio passes RUST_LOG verbatim into mpv's msg-level; non-mpv
            # values like "crate=debug" make mpv creation fail with -11
            --unset RUST_LOG \
            # libmpv refuses to initialize unless LC_NUMERIC is C ("Non-C locale detected",
            # "Failed to create mpv: Null" panic); beta.12 called setlocale() in code, v1.1.4 doesn't
            --unset LC_ALL \
            --set LC_NUMERIC "C" \
            --set SERVER_PATH "$out/share/stremio/server.js" \
            --prefix PATH : "${lib.makeBinPath [pkgs.nodejs]}" \
            --prefix LD_LIBRARY_PATH : "/run/opengl-driver/lib" \
            --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [pkgs.libGL]}" \
            --prefix PATH : "${lib.makeBinPath [pkgs.bubblewrap]}"
          )
        '';

        meta = {
          description = "Modern media center (WebKitGTK-based)";
          homepage = "https://www.stremio.com/";
          license = [lib.licenses.gpl3Only lib.licenses.unfree];
          platforms = lib.platforms.linux;
          mainProgram = "stremio";
        };
      }))
    ];
  };
}

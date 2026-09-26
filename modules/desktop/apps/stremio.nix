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
      (pkgs.rustPlatform.buildRustPackage (_finalAttrs: {
        pname = "stremio-linux-shell";
        version = "1.1.4-unstable-3826d3c";

        src = pkgs.fetchFromGitHub {
          owner = "Stremio";
          repo = "stremio-linux-shell";
          rev = "3826d3c9a97e83d218b6bf87321f2817065cef46";
          hash = "sha256-Y5BkMviHM1+DcwUrrv4eqCLjawKfA4ZaohjgpFQjjFk=";
        };

        cargoLock = {
          lockFile = ./stremio-Cargo.lock;
        };

        postPatch = ''
          substituteInPlace src/app/video/imp.rs \
            --replace-fail 'init.set_property("vo", "libmpv")?;' \
              'init.set_property("vo", "libmpv")?; init.set_property("ao", "pulse")?;'

          export HOME=/build
        '';

        nativeBuildInputs = [
          pkgs.wrapGAppsHook4
          pkgs.makeBinaryWrapper
          pkgs.pkg-config
          pkgs.gettext
          pkgs.glib.bin
        ];

        buildInputs = [
          pkgs.gtk4
          pkgs.libadwaita
          pkgs.webkitgtk_6_0
          pkgs.glib-networking
          pkgs.libepoxy
          pkgs.mpv
        ];

        postInstall = ''
          mkdir -p $out/share/applications $out/share/icons/hicolor/scalable/apps \
                   $out/share/glib-2.0/schemas $out/share/stremio
          cp data/com.stremio.Stremio.desktop $out/share/applications/
          cp data/icons/com.stremio.Stremio.svg $out/share/icons/hicolor/scalable/apps/
          cp data/com.stremio.Stremio.gschema.xml $out/share/glib-2.0/schemas/
          cp data/server.js $out/share/stremio/server.js

          glib-compile-schemas "$out/share/glib-2.0/schemas"

          cat > $out/bin/stremio <<'SH'
          #!/bin/sh
          [ -e /dev/nvidia0 ] && export GSK_RENDERER=opengl
          exec "$(dirname "$0")/stremio-linux-shell" --no-window-decorations "$@"
          SH
          chmod +x $out/bin/stremio
        '';

        preFixup = ''
          gappsWrapperArgs+=(
            --unset RUST_LOG \
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

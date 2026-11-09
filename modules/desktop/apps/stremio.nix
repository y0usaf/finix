{
  lib,
  pkgs,
  ...
}: {
  user.persist.directories = [
    ".local/share/stremio"
    ".local/share/stremio-linux-shell"
    ".stremio-server"
  ];
  environment.systemPackages = [
    (pkgs.rustPlatform.buildRustPackage (_finalAttrs: {
      pname = "stremio-linux-shell";
      version = "1.2.2-unstable-97078df9";

      src = pkgs.fetchFromGitHub {
        owner = "Stremio";
        repo = "stremio-linux-shell";
        rev = "97078df902462e613757571d307a9ac16843147a";
        hash = "sha256-OWE0BapfjD7al5Dab6UjceYs2vckIwdpJis7ky04eIY=";
      };

      cargoLock = {
        lockFile = ../../../locks/stremio-Cargo.lock;
        outputHashes = {
          "libmpv2-5.0.3" = "sha256-EhADLuOxJe2xYEXfwYRNSlFVuuV10TxqmwsG9oZPG3c=";
          "libmpv2-sys-4.0.1" = "sha256-EhADLuOxJe2xYEXfwYRNSlFVuuV10TxqmwsG9oZPG3c=";
        };
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
}

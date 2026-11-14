{
  lib,
  pkgs,
  ...
}: let
  helium = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "helium";
    version = "0.21.3.1";

    src = pkgs.fetchurl {
      url = "https://github.com/imputnet/helium-linux/releases/download/${finalAttrs.version}/helium-${finalAttrs.version}-x86_64_linux.tar.xz";
      hash = "sha256-iPPFOiNxguhyrDBhzIwSnnWuy86Erq2DQiXYEDCWwlQ=";
    };

    nativeBuildInputs = [pkgs.autoPatchelfHook pkgs.makeWrapper];
    buildInputs = [
      pkgs.alsa-lib
      pkgs.at-spi2-core
      pkgs.cairo
      pkgs.cups
      pkgs.dbus
      pkgs.expat
      pkgs.glib
      pkgs.gtk3
      pkgs.libdrm
      pkgs.libgbm
      pkgs.libxkbcommon
      pkgs.libx11
      pkgs.libxcb
      pkgs.libxcomposite
      pkgs.libxdamage
      pkgs.libxext
      pkgs.libxfixes
      pkgs.libxrandr
      pkgs.nspr
      pkgs.nss
      pkgs.pango
      pkgs.stdenv.cc.cc.lib
      pkgs.udev
    ];
    runtimeDependencies = [pkgs.libglvnd pkgs.libpulseaudio (lib.getLib pkgs.libva) pkgs.pipewire pkgs.wayland];
    autoPatchelfIgnoreMissingDeps = ["libQt5*" "libQt6*"];

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib" "$out/bin" "$out/share/applications" "$out/share/icons/hicolor/256x256/apps"
      cp -a . "$out/lib/helium"
      rm "$out/lib/helium/libqt5_shim.so" "$out/lib/helium/libqt6_shim.so"
      makeWrapper "$out/lib/helium/helium" "$out/bin/helium" \
        --set CHROME_WRAPPER "$out/bin/helium" \
        --prefix PATH : '${lib.makeBinPath [pkgs.xdg-utils]}' \
        --prefix XDG_DATA_DIRS : ${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name} \
        --add-flags '--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations'
      cp helium.desktop "$out/share/applications/helium.desktop"
      cp product_logo_256.png "$out/share/icons/hicolor/256x256/apps/helium.png"
      substituteInPlace "$out/share/applications/helium.desktop" --replace-quiet 'Exec=helium' "Exec=$out/bin/helium"
      runHook postInstall
    '';

    dontStrip = true;
    meta = {
      description = "Helium browser, repackaged from imputnet's Linux release";
      homepage = "https://helium.computer";
      license = lib.licenses.gpl3Only;
      platforms = ["x86_64-linux"];
      mainProgram = "helium";
    };
  });
in {
  environment.systemPackages = [helium];
  system.build.helium = helium;
  user.persist.directories = [
    ".config/net.imput.helium"
    ".cache/net.imput.helium"
  ];
}

{
  config,
  lib,
  pkgs,
  ...
}: let
  # CEF pinned to match upstream stremio-linux-shell requirements
  # https://github.com/Stremio/stremio-linux-shell/blob/v1.0.0-beta.12/flatpak/com.stremio.Stremio.Devel.json#L150
  cefPinned = pkgs.cef-binary.override {
    version = "138.0.21";
    gitRevision = "54811fe";
    chromiumVersion = "138.0.7204.101";
    srcHashes = {
      aarch64-linux = "";
      x86_64-linux = "sha256-Kob/5lPdZc9JIPxzqiJXNSMaxLuAvNQKdd/AZDiXvNI=";
    };
  };

  cefPath = pkgs.symlinkJoin {
    name = "stremio-cef-target";
    paths = [
      "${cefPinned}/Resources"
      "${cefPinned}/Release"
    ];
  };
in {
  options.user.programs.stremio = {
    enable = lib.mkEnableOption "Stremio media center";
  };
  config = lib.mkIf config.user.programs.stremio.enable {
    environment.systemPackages = [
      (pkgs.rustPlatform.buildRustPackage (finalAttrs: {
        pname = "stremio-linux-shell";
        version = "0-unstable-2eb0252f";

        src = pkgs.fetchFromGitHub {
          owner = "Stremio";
          repo = "stremio-linux-shell";
          rev = "2eb0252fb568eaba829c9289e5ce49db6378f734";
          hash = "sha256-NVChTlW146AAHtpeLrCEJBhWmOM7FvrSv9H/KMLJiNY=";
        };

        cargoLock = {
          lockFile = "${finalAttrs.src}/Cargo.lock";
          outputHashes = {
            "cef-138.2.2+138.0.21" = "sha256-HfhiNwhCtKcuI27fGTCjk1HA1Icau6SUjXjHqAOllAk=";
            "dpi-0.1.1" = "sha256-5nc8cGFl4jUsJXfEtfOxFBQFRoBrM6/5xfA2c1qhmoQ=";
            "glutin-0.32.3" = "sha256-5IX+03mQmWxlCdVC0g1q2J+ulW+nPTAhYAd25wyaHx8=";
            "libmpv2-4.1.0" = "sha256-zXMFuajnkY8RnVGlvXlZfoMpfifzqzJnt28a+yPZmcQ=";
          };
        };

        postPatch = ''
          substituteInPlace $cargoDepsCopy/libappindicator-sys-*/src/lib.rs \
            --replace-fail "libayatana-appindicator3.so.1" "${pkgs.libayatana-appindicator}/lib/libayatana-appindicator3.so.1"
        '';

        buildFeatures = ["offline-build"];

        buildInputs = [
          pkgs.atk
          cefPath
          pkgs.gtk3
          pkgs.libayatana-appindicator
          pkgs.mpv
          pkgs.openssl
        ];

        nativeBuildInputs = [
          pkgs.wrapGAppsHook4
          pkgs.makeBinaryWrapper
          pkgs.pkg-config
        ];

        env.CEF_PATH = "${cefPath}";

        postInstall = ''
          mkdir -p $out/share/applications
          cp data/com.stremio.Stremio.desktop $out/share/applications/com.stremio.Stremio.desktop

          mkdir -p $out/share/icons/hicolor/scalable/apps
          cp data/icons/com.stremio.Stremio.svg $out/share/icons/hicolor/scalable/apps/com.stremio.Stremio.svg

          cp data/server.js $out/bin/server.js
          mv $out/bin/stremio-linux-shell $out/bin/stremio
        '';

        preFixup = ''
          gappsWrapperArgs+=(
            --prefix LD_LIBRARY_PATH : "/run/opengl-driver/lib" \
            --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [pkgs.libGL]}" \
            --prefix PATH : "${lib.makeBinPath [pkgs.nodejs]}"
          )
        '';

        meta = {
          description = "Modern media center (CEF-based, no qtwebengine)";
          homepage = "https://www.stremio.com/";
          license = [lib.licenses.gpl3Only lib.licenses.unfree];
          platforms = lib.platforms.linux;
          mainProgram = "stremio";
        };
      }))
    ];
  };
}

{
  config,
  lib,
  pkgs,
  ...
}: let
  unwrapped = pkgs.stdenv.mkDerivation {
    pname = "chatgpt";
    version = "26.924.51851";

    src = pkgs.fetchurl {
      url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/pool/main/c/chatgpt/chatgpt_26.924.51851_amd64.deb";
      hash = "sha256-fSW5n+ObA83D2DYx+yA9t3GGeIpTOHreDnBqJh6JaTU=";
    };

    nativeBuildInputs = [pkgs.dpkg pkgs.autoPatchelfHook pkgs.makeWrapper];
    buildInputs = with pkgs; [
      alsa-lib
      at-spi2-core
      cairo
      cups
      dbus
      expat
      glib
      gtk3
      libdrm
      libgbm
      libglvnd
      libnotify
      libusb1
      libx11
      libxcb
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxkbcommon
      libxrandr
      nspr
      nss
      openssl
      pango
      stdenv.cc.cc.lib
      tpm2-tss
      udev
    ];
    runtimeDependencies = with pkgs; [libnotify libsecret libpulseaudio wayland];

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb -x "$src" .
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib" "$out/bin"
      cp -a usr/lib/chatgpt "$out/lib/"
      cp -a usr/share "$out/"
      rm "$out/lib/chatgpt/libqt5_shim.so" "$out/lib/chatgpt/libqt6_shim.so"
      find "$out/lib/chatgpt" -type d -name '*-musl' -prune -exec rm -r {} +
      find "$out/lib/chatgpt" -type f -name '*.musl.node' -delete
      makeWrapper "$out/lib/chatgpt/ChatGPT" "$out/bin/chatgpt" \
        --prefix PATH : ${lib.makeBinPath [pkgs.coreutils pkgs.git pkgs.xdg-utils pkgs.bubblewrap pkgs.glib]} \
        --prefix XDG_DATA_DIRS : ${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name} \
        --run '${pkgs.coreutils}/bin/mkdir -p "''${CODEX_HOME:-$HOME/.codex}"' \
        --run '
          set -e
          resources="''${XDG_CACHE_HOME:-$HOME/.cache}/chatgpt/'"$(basename "$out")"'"
          if [ ! -d "$resources/plugins" ]; then
            mkdir -p "$(dirname "$resources")"
            staging=$(mktemp -d "$(dirname "$resources")/.resources.XXXXXX")
            trap "rm -rf \"$staging\"" EXIT
            for resource in "'"$out"'/lib/chatgpt/resources/"*; do
              [ "$(basename "$resource")" = plugins ] || ln -s "$resource" "$staging/"
            done
            cp -r --no-preserve=mode "'"$out"'/lib/chatgpt/resources/plugins" "$staging/"
            if ! mv -T "$staging" "$resources"; then
              [ -d "$resources/plugins" ] || exit 1
              rm -rf "$staging"
            fi
            trap - EXIT
          fi
          export CODEX_ELECTRON_BUNDLED_PLUGINS_RESOURCES_PATH="$resources"
        ' \
        --add-flags '--ozone-platform-hint=auto'
      substituteInPlace "$out/share/applications/chatgpt.desktop" \
        --replace-fail 'Exec=chatgpt %U' "Exec=$out/bin/chatgpt %U"
      runHook postInstall
    '';

    dontStrip = true;
    meta = {
      description = "ChatGPT desktop app with Codex";
      homepage = "https://learn.chatgpt.com/docs/linux/linux-app";
      license = lib.licenses.unfree;
      platforms = ["x86_64-linux"];
      mainProgram = "chatgpt";
    };
  };
  chatgpt = pkgs.buildFHSEnv {
    name = "chatgpt";
    targetPkgs = _: unwrapped.buildInputs ++ unwrapped.runtimeDependencies;
    runScript = "${unwrapped}/bin/chatgpt";
    extraInstallCommands = ''
      cp -r ${unwrapped}/share "$out/"
      chmod u+w "$out/share/applications/chatgpt.desktop"
      substituteInPlace "$out/share/applications/chatgpt.desktop" \
        --replace-fail '${unwrapped}/bin/chatgpt' "$out/bin/chatgpt"
    '';
    inherit (unwrapped) meta;
  };
in {
  environment.systemPackages = [chatgpt];
  system.build.chatgpt = chatgpt;
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/Codex"
    ".codex-workspaces"
  ];
}

{
  config,
  lib,
  pkgs,
  ...
}: let
  unwrapped = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "grok-bot-unwrapped";
    version = "0.75.8";

    src = pkgs.fetchurl {
      url = "https://downloads.cursor.com/grokbot/stable/039d88c52f45f8af72fbe7379bc426c171edf62b/linux/x64/grok-bot_${finalAttrs.version}_amd64.deb";
      hash = "sha256-Q0ZdsVih2dYYqe+caKrqBj3jQjRG+vdiq+fuSP99Jrs=";
    };

    nativeBuildInputs = [pkgs.dpkg pkgs.autoPatchelfHook];
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
      pkgs.libglvnd
      pkgs.libnotify
      pkgs.libsecret
      pkgs.libx11
      pkgs.libxcb
      pkgs.libxcomposite
      pkgs.libxdamage
      pkgs.libxext
      pkgs.libxfixes
      pkgs.libxkbcommon
      pkgs.libxrandr
      pkgs.libxscrnsaver
      pkgs.libxtst
      pkgs.nspr
      pkgs.nss
      pkgs.openssl
      pkgs.pango
      pkgs.stdenv.cc.cc.lib
      pkgs.udev
      pkgs.util-linux
    ];
    runtimeDependencies = [pkgs.libpulseaudio pkgs.wayland];

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb -x "$src" .
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib"
      cp -a "opt/Grok Bot" "$out/lib/grok-bot"
      cp -a usr/share "$out/"
      runHook postInstall
    '';

    dontStrip = true;
    meta = {
      description = "Grok Bot desktop app, repackaged from Cursor's official Debian package";
      homepage = "https://cursor.com";
      license = lib.licenses.unfree;
      platforms = ["x86_64-linux"];
    };
  });

  grok-bot-desktop = pkgs.stdenv.mkDerivation {
    pname = "grok-bot";
    inherit (unwrapped) version;

    nativeBuildInputs = [pkgs.makeWrapper];

    dontUnpack = true;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/bin" "$out/share"
      ln -s ${unwrapped}/lib "$out/lib"
      cp -a ${unwrapped}/share/. "$out/share/"
      makeWrapper ${unwrapped}/lib/grok-bot/grok-bot "$out/bin/grok-bot" \
        --prefix PATH : '${lib.makeBinPath [pkgs.coreutils pkgs.util-linux pkgs.xdg-utils]}' \
        --prefix XDG_DATA_DIRS : ${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name} \
        --add-flags '--ozone-platform-hint=auto'
      substituteInPlace "$out/share/applications/grok-bot.desktop" \
        --replace-fail 'Exec=grok-bot %U' "Exec=$out/bin/grok-bot %U"
      runHook postInstall
    '';

    meta =
      unwrapped.meta
      // {
        mainProgram = "grok-bot";
      };
  };
in {
  environment.systemPackages = [grok-bot-desktop];
  system.build.grok-bot-desktop = grok-bot-desktop;
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/Grok Bot"
    ".grokbot"
  ];
}

# Materialized packages: the NixOS program/service modules never exposed
# these as environment.systemPackages entries — their module materialized
# the package internally (programs.steam, programs.pi, virtualisation.podman,
# services.tailscale, …). compat-import drops those namespaces, so the
# packages are declared here explicitly.
#
# Guards mirror the bridge-era desktop reality. Two are unconditional:
# tailscaled runs natively under finix (parity.nix) so the CLI must exist;
# syncthing backs the syncthing-proxy setup the same way.
{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  glideRuntimeLibs = [
    pkgs.alsa-lib
    pkgs.gtk3
    pkgs.libdbusmenu
    pkgs.libevent
    pkgs.libnotify
    pkgs.libpulseaudio
    pkgs.libva
    pkgs.mesa
    pkgs.pango
    pkgs.pipewire
    pkgs.stdenv.cc.cc.lib
    pkgs.xorg.libX11
    pkgs.xorg.libXcomposite
    pkgs.xorg.libXdamage
    pkgs.xorg.libXext
    pkgs.xorg.libXfixes
    pkgs.xorg.libXrandr
    pkgs.xorg.libXtst
  ];
  glide = pkgs.stdenv.mkDerivation {
    pname = "glide";
    version = "0.1.63a";

    src = pkgs.fetchurl {
      url = "https://github.com/glide-browser/glide/releases/download/0.1.63a/glide.linux-x86_64.tar.xz";
      hash = "sha256-idHArAa57FADdmhCI/5vK47SEd0dlz0diH4DRDmKDmE=";
    };

    sourceRoot = "glide";
    nativeBuildInputs = [pkgs.patchelf];
    buildInputs = glideRuntimeLibs;

    installPhase = ''
      mkdir -p $out/lib/glide $out/bin
      cp -r . $out/lib/glide/
      ln -s $out/lib/glide/glide $out/bin/glide
    '';

    postFixup = ''
      runtimeRpath="$out/lib/glide:${lib.makeLibraryPath glideRuntimeLibs}"
      for file in "$out"/lib/glide/*; do
        if patchelf --print-rpath "$file" >/dev/null 2>&1; then
          patchelf --set-rpath "$runtimeRpath" "$file"
        fi
      done
      for file in glide glide-bin crashreporter crashhelper glxtest pingsender vaapitest vulkantest; do
        patchelf --set-interpreter "${pkgs.stdenv.cc.libc}/lib/ld-linux-x86-64.so.2" "$out/lib/glide/$file"
      done
    '';
  };
in {
  environment.systemPackages =
    [
      glide
      # tailscaled runs natively under finix (parity.nix) — CLI required.
      pkgs.tailscale
      pkgs.syncthing
      # podman only: docker/compose CLIs stay excluded (deferred wholesale).
      pkgs.podman
      # gtk file dialogs/portals (NixOS materialized via services.gvfs).
      pkgs.gvfs
      # Baseline utilities the NixOS universe added implicitly.
      pkgs.rsync
      pkgs.bind
      pkgs.btrbk
      pkgs.fuse3
      pkgs.shared-mime-info
      pkgs.strace
    ]
    ++ lib.optionals config.user.gaming.steam.enable [
      # compat-import drops programs.*, so programs.steam.extraCompatPackages
      # (proton-ge-bin) never reaches Steam under finix — GE-Proton is in the
      # store but STEAM_EXTRA_COMPAT_TOOLS_PATHS stays unset, so the compat
      # tool dropdown never lists it. Bake the path into the wrapper instead.
      (
        if config.user.gaming.proton.enable
        then
          pkgs.steam.override {
            extraEnv.STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${pkgs.proton-ge-bin.steamcompattool}";
          }
        else pkgs.steam
      )
      pkgs.steam-run
    ]
    # pi-full = every extension at registry stage "active" in pi-flake.
    # Promotion there is deployment here; there is no host-side allowlist.
    ++ lib.optional config.user.dev.pi.enable
    flakeInputs.pi-flake.packages."${pkgs.stdenv.hostPlatform.system}".pi-full;
}

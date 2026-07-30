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
}: {
  environment.systemPackages =
    [
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

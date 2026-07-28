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
      pkgs.steam
      pkgs.steam-run
    ]
    ++ lib.optional config.user.dev.pi.enable
    (flakeInputs.pi-flake.lib.piWithExtensionFlags {
      inherit pkgs;
      extensionFlags = {
        "gecko-websearch" = true;
        rtk = true;
        minimal = true;
        interview = true;
        "tool-management" = true;
        webfetch = true;
        hashline = true;
        advisor = true;
        review = true;
        vcc = true;
        caveman = true;
        atelier = true;
        aphrodite = true;
        "extensible-workflows" = true;
      };
    });
}

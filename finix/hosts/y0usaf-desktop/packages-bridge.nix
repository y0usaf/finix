# Package parity with NixOS, without double bookkeeping: evaluate the
# NixOS system for this same host and reuse its environment.systemPackages
# LIST. The module-universe split forbids importing NixOS *modules*; it
# says nothing about consuming the evaluated *derivations*, which are
# universe-agnostic. Add an app on the NixOS side → finix inherits it on
# the next deploy. One source of truth.
#
# Costs, accepted deliberately:
#   - finix eval now also evals the NixOS config (~seconds + RAM)
#   - closure grows to daily-driver size — shared /nix/store dedupes it
#     against the NixOS generations already on disk
#   - NixOS side builds with cudaSupport=true; bridged drvs come from THAT
#     pkgs instance (also why unfree apps arrive pre-blessed by the NixOS
#     allowlist — finix's own allowUnfreePredicate never re-evaluates them)
#
# Apps that DEPEND on absent infrastructure still won't function until 2c
# lands it: audio (pipewire), portals (screenshare/file pickers), anything
# shelling out to systemctl. The binaries being present is still correct —
# they light up the moment the service ports land.
{
  lib,
  flakeInputs,
  ...
}: let
  nixosCfg = flakeInputs.self.nixosConfigurations.y0usaf-desktop.config;

  # Daemon binaries whose SERVICES are deliberately not (or differently)
  # provided here; shipping the CLIs would only invite confusion.
  denyList = [
    "networkmanager" # finix runs dhcpcd + static fallback
    "docker" # deferred wholesale (NOTES phase-1 scope)
    "docker-compose"
  ];

  pname = p: p.pname or (lib.getName p);
  bridged =
    builtins.filter (p: !(builtins.elem (pname p) denyList))
    nixosCfg.environment.systemPackages;
in {
  environment.systemPackages = bridged;
}

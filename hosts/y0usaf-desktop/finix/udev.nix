# udev rules: the bridge era sanitized nixpkgs' services.udev.packages
# (sed-stripped systemd lines, eudev hard-fails on dangling systemd paths)
# and the list included steam-devices + i2c + NixOS-baseline noise. Native:
#
#   - upower / udisks2 / i2c / bluetooth: finix's own modules (parity.nix)
#     ship their rules — nothing to do here.
#   - steam-devices: controllers (DualSense, Nintendo, VR…), sanitized.
#
# First-party rules (vial, DualSense, uinput, video group, …) are NOT
# mirrored here: modules declare them as services.udev.packages entries,
# which NixOS and finix both honor and the compat shim forwards — one
# declaration mechanism, no catch-all. finix has no extraRules option;
# anything still using NixOS's extraRules is dropped by the shim on purpose.
{ pkgs, ... }:
  # Same sanitize as the bridge: drop any rule line shelling out to systemd.
{
  services.udev.packages = [
    ((p:
    pkgs.runCommand "${p.pname or (builtins.parseDrvName p.name).name}-definit" {} ''
      mkdir -p $out/lib/udev/rules.d
      find ${p}/ -type f -name "*.rules" | while read -r f; do
        ${pkgs.gnused}/bin/sed '/systemd/d' "$f" \
          > "$out/lib/udev/rules.d/$(basename "$f")"
      done
    '') pkgs.steam-devices-udev-rules)
  ];
}

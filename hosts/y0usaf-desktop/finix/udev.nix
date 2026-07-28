# udev rules: the bridge era sanitized nixpkgs' services.udev.packages
# (sed-stripped systemd lines, eudev hard-fails on dangling systemd paths)
# and the list included steam-devices + i2c + NixOS-baseline noise. Native:
#
#   - upower / udisks2 / i2c / bluetooth: finix's own modules (parity.nix)
#     ship their rules — nothing to do here.
#   - steam-devices: controllers (DualSense, Nintendo, VR…), sanitized.
#   - vial + DualSense hidraw: raw extraRules from modules/core/hardware/
#     input.nix — finix udev has no extraRules option, so they are written
#     out as a rules package here.
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
    (pkgs.writeTextFile {
    name = "phoenix-udev-rules";
    destination = "/lib/udev/rules.d/99-phoenix.rules";
    text = ''
      # vial (QMK keyboard configurator) — modules/core/hardware/input.nix
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", TAG+="uaccess"
      # DualSense (054c:0ce6, 054c:0df2) — controllers.enable on desktop
      KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ce6", MODE="0660", TAG+="uaccess"
      KERNEL=="hidraw*", KERNELS=="*054C:0CE6*", MODE="0660", TAG+="uaccess"
      KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0df2", MODE="0660", TAG+="uaccess"
    '';
  })
  ];
}

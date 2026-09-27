{pkgs, ...}: {
  services.udev.packages = [
    (pkgs.runCommand "steam-devices-udev-rules-definit" {} ''
      mkdir -p $out/lib/udev/rules.d
      find ${pkgs.steam-devices-udev-rules}/ -type f -name "*.rules" | while read -r f; do
        ${pkgs.gnused}/bin/sed '/systemd/d' "$f" \
          > "$out/lib/udev/rules.d/$(basename "$f")"
      done
    '')
  ];
}

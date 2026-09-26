{pkgs, ...}: {
  services.udev.packages = [
    ((p:
      pkgs.runCommand "${p.pname or (builtins.parseDrvName p.name).name}-definit" {} ''
        mkdir -p $out/lib/udev/rules.d
        find ${p}/ -type f -name "*.rules" | while read -r f; do
          ${pkgs.gnused}/bin/sed '/systemd/d' "$f" \
            > "$out/lib/udev/rules.d/$(basename "$f")"
        done
      '')
    pkgs.steam-devices-udev-rules)
  ];
}

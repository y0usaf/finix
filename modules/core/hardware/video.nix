{pkgs, ...}: {
  # Rules as a package, not extraRules: services.udev.packages exists on
  # both NixOS and finix (the compat shim forwards it), extraRules is
  # NixOS-only and silently dropped on finix. One declaration, both distros.
  config.services.udev.packages = [
    (pkgs.writeTextFile {
      name = "video-group-rules";
      destination = "/lib/udev/rules.d/99-video-group.rules";
      text = ''
        KERNEL=="video[0-9]*", GROUP="video", MODE="0660"
      '';
    })
  ];
}

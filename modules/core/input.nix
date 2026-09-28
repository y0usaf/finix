{pkgs, ...}: {
  services.udev.packages = [
    (pkgs.writeTextFile {
      name = "vial";
      text = ''
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users"
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", TAG+="uaccess"
      '';
      destination = "/lib/udev/rules.d/99-vial.rules";
    })
  ];
}

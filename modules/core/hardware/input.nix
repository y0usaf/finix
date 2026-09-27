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
    (pkgs.writeTextFile {
      name = "dualsense";
      text = ''
        KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ce6", MODE="0660", TAG+="uaccess"
        KERNEL=="hidraw*", KERNELS=="*054C:0CE6*", MODE="0660", TAG+="uaccess"
        KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0df2", MODE="0660", TAG+="uaccess"
      '';
      destination = "/lib/udev/rules.d/99-dualsense.rules";
    })
  ];
}

{pkgs, ...}: {
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

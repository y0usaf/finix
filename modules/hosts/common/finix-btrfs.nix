_: {
  boot.initrd = {
    kernelModules = ["btrfs"];
    supportedFilesystems.btrfs.enable = true;
  };
}

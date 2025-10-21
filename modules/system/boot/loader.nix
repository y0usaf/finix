_: {
  config = {
    boot.loader = {
      systemd-boot.enable = false;
      limine.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
  };
}

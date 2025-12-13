_: {
  config = {
    boot.loader = {
      limine.enable = true;
      efi = {
        canTouchEfiVariables = false;
        efiSysMountPoint = "/boot";
      };
    };
  };
}

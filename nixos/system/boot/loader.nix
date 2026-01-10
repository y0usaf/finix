_: {
  config = {
    boot.loader = {
      limine = {
        enable = true;
        maxGenerations = 20;
      };
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
  };
}

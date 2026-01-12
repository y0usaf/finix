_: {
  config = {
    boot.loader = {
      limine = {
        enable = true;
        maxGenerations = 20;
        validateChecksums = false;
      };
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
  };
}

_: {
  config = {
    boot.loader = {
      limine = {
        enable = true;
        maxGenerations = 5;
        secureBoot.enable = true;
      };
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
  };
}

_: {
  config = {
    boot.loader = {
      limine = {
        enable = true;
        maxGenerations = 20;
        secureBoot.enable = true;
      };
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
  };
}

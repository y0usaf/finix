{flakeInputs, ...}: {
  imports = [
    flakeInputs.manzil.nixosModules.default
    flakeInputs.tweakcc.nixosModules.default
    flakeInputs.impermanence.nixosModules.impermanence
    flakeInputs.nvtune.nixosModules.default
  ];
  manzil = {
    clobberByDefault = true;
    users = {};
  };
}

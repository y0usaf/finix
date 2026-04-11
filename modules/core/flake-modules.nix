{flakeInputs, ...}: {
  imports = [
    (flakeInputs.disko + "/module.nix")
    flakeInputs.bayt.nixosModules.default
    flakeInputs.tweakcc.nixosModules.default
    flakeInputs.mango.nixosModules.mango
    flakeInputs.impermanence.nixosModules.impermanence
    flakeInputs.patchix.nixosModules.default
    flakeInputs.nvtune.nixosModules.default
  ];
  bayt = {
    clobberByDefault = true;
    users = {};
  };
}

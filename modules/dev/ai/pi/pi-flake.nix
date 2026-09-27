{
  pkgs,
  flakeInputs,
  ...
}: {
  environment.systemPackages = [
    flakeInputs.pi-harness.packages."${pkgs.stdenv.hostPlatform.system}".default
    flakeInputs.pi-flake.packages."${pkgs.stdenv.hostPlatform.system}".pi
  ];
}

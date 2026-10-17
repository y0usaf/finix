{
  pkgs,
  flakeInputs,
  ...
}: {
  environment.systemPackages = [
    flakeInputs.iets.packages."${pkgs.stdenv.hostPlatform.system}".default
  ];
}

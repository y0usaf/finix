{
  pkgs,
  flakeInputs,
  ...
}: {
  environment.systemPackages = [
    flakeInputs.strictix.packages."${pkgs.stdenv.hostPlatform.system}".default
  ];
}

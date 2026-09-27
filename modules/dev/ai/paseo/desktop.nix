{
  pkgs,
  flakeInputs,
  ...
}: {
  environment.systemPackages = [
    flakeInputs.paseo.packages."${pkgs.stdenv.hostPlatform.system}".desktop
  ];
}

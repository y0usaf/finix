{
  pkgs,
  flakeInputs,
  ...
}: {
  environment.systemPackages = [
    flakeInputs.emeraldian.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}

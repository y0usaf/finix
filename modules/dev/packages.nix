{
  pkgs,
  flakeInputs,
  ...
}: {
  environment.systemPackages = [
    flakeInputs.pi-flake.packages."${pkgs.stdenv.hostPlatform.system}".pi-full
    pkgs.texliveFull
    pkgs.texstudio
    pkgs.tectonic
    flakeInputs.paseo.packages."${pkgs.stdenv.hostPlatform.system}".desktop
  ];
}

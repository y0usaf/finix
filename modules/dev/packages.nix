{
  pkgs,
  flakeInputs,
  ...
}: {
  environment.systemPackages = [
    pkgs.texliveFull
    pkgs.texstudio
    pkgs.tectonic
    flakeInputs.paseo.packages."${pkgs.stdenv.hostPlatform.system}".desktop
  ];
}

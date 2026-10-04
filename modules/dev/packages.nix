{
  pkgs,
  flakeInputs,
  ...
}: {
  environment.systemPackages = [
    (pkgs.lib.hiPrio flakeInputs.pi.packages."${pkgs.stdenv.hostPlatform.system}".default)
    flakeInputs.durapi.packages."${pkgs.stdenv.hostPlatform.system}".default
    pkgs.texliveFull
    pkgs.texstudio
    pkgs.tectonic
    flakeInputs.paseo.packages."${pkgs.stdenv.hostPlatform.system}".desktop
  ];
}

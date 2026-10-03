{
  pkgs,
  flakeInputs,
  ...
}: {
  environment.systemPackages = [
    (pkgs.lib.hiPrio flakeInputs.pi-flake.packages."${pkgs.stdenv.hostPlatform.system}".pi-full)
    flakeInputs.pi-flake.packages."${pkgs.stdenv.hostPlatform.system}".durapi-full
    pkgs.texliveFull
    pkgs.texstudio
    pkgs.tectonic
    flakeInputs.paseo.packages."${pkgs.stdenv.hostPlatform.system}".desktop
  ];
}

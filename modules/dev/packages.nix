{
  pkgs,
  inputPackages,
  ...
}: {
  environment.systemPackages = [
    (pkgs.lib.hiPrio inputPackages.pi.default)
    inputPackages.durapi.default
    pkgs.texliveFull
    pkgs.texstudio
    pkgs.tectonic
    inputPackages.paseo.desktop
  ];
}

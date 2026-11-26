{
  pkgs,
  inputPackages,
  ...
}: {
  environment.systemPackages = [
    pkgs.nix
    pkgs.efibootmgr
    pkgs.rsync
    inputPackages.oh-my-pi.omp
  ];
}

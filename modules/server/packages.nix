{pkgs, ...}: {
  environment.systemPackages = [pkgs.nix pkgs.efibootmgr];
}

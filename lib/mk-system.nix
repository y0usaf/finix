# mkFinixSystem: the shared builder for every finix system in this repo.
# finix uses its own module system (finit/providers option tree) - NixOS
# modules under ../modules are NOT importable here and never will be.
# Shared baseline: bash, dhcpcd, getty, openssh, sudo, sysklogd + our
# common.nix workarounds (see modules/finix/NOTES.md "Upstream finix bugs/gaps").
{
  lib,
  pkgs,
  inputs,
}: modules:
inputs.finix.lib.finixSystem {
  inherit lib;
  specialArgs = {
    modulesPath = toString inputs.nixpkgs + "/nixos/modules";
    # Flake inputs for hosts that pull packages from them (e.g. pi).
    flakeInputs = inputs;
  };
  modules = with inputs.finix.nixosModules;
    [
      {nixpkgs.pkgs = lib.mkDefault pkgs;}
      bash
      dhcpcd
      getty
      openssh
      sudo
      sysklogd
      ../modules/finix/common.nix
    ]
    ++ modules;
}

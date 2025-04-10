# Re-export the contents of hosts.nix
{lib, pkgs, ...}: 
import ./hosts.nix {inherit lib pkgs;}
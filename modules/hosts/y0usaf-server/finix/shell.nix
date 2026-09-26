{
  lib,
  pkgs,
  ...
}: {
  users.users.y0usaf.shell = lib.mkForce "${pkgs.bashInteractive}/bin/bash";
}

# /home/y0usaf/nixos/modules/home/gaming/marvel-rivals/engine.nix
# Manages the Marvel Rivals Engine.ini file
{
  pkgs,
  lib,
  ...
}: let
  mkNixLink = import ../../../helpers/nixlink.nix {inherit pkgs lib;};

  targetPath = ".local/share/Steam/steamapps/compatdata/2767030/pfx/drive_c/users/steamuser/AppData/Local/Marvel/Saved/Config/Windows/Engine.ini";

  # Read content from pkg directory
  content = builtins.readFile ../../../../pkg/gaming-config/marvel-rivals/Engine.ini;
in
  mkNixLink {
    inherit content path;
    drvName = "mr-engine-ini";
  }

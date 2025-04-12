# /home/y0usaf/nixos/modules/home/gaming/marvel-rivals/gameusersettings.nix
# Manages the Marvel Rivals GameUserSettings.ini file
{
  pkgs,
  lib,
  ...
}: let
  mkNixLink = import ../../../helpers/nixlink.nix {inherit pkgs lib;};

  targetPath = ".local/share/Steam/steamapps/compatdata/2767030/pfx/drive_c/users/steamuser/AppData/Local/Marvel/Saved/Config/Windows/GameUserSettings.ini";

  # Read content from pkg directory
  content = builtins.readFile ../../../../pkg/gaming-config/marvel-rivals/GameUserSettings.ini;
in
  mkNixLink {
    inherit content path;
    drvName = "mr-gameusersettings-ini";
  }

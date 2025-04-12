# modules/home/gaming/wukong/engine.nix
# Manages the Wukong Engine.ini file
{
  pkgs, # Needed by the helper
  lib, # Needed by the helper
  ...
}: let
  # Import the helper function
  mkNixLink = import ../../../helpers/nixlink.nix {inherit pkgs lib;};

  # Define the target path relative to $HOME
  targetPath = ".local/share/Steam/steamapps/compatdata/2358720/pfx/drive_c/users/steamuser/AppData/Local/b1/Saved/Config/Windows/Engine.ini";

  # Define the file content by reading from the pkg directory
  # Ensure the source file exists at this relative path
  content = builtins.readFile ../../../../pkg/gaming-config/wukong/Engine.ini;
in
  # Call the helper function to generate the home.file configuration
  mkNixLink {
    inherit content path;
    drvName = "wukong-engine-ini"; # Optional but good practice
  }

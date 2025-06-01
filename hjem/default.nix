# Default hjem module
# This imports all submodules
{ lib, config, pkgs, ... }:

let
  # Collect all directories that contain modules
  moduleNames = builtins.attrNames (builtins.readDir ./.); 
  # Filter out only directories (excluding default.nix)
  moduleDirs = builtins.filter (name: 
    name != "default.nix" && 
    builtins.pathExists (./. + "/${name}") && 
    builtins.pathExists (./. + "/${name}/default.nix")
  ) moduleNames;
  # Create a list of module imports
  moduleImports = builtins.map (name: ./. + "/${name}") moduleDirs;
in {
  # Provide a test file directly from this module
  files = {
    ".config/HJEM_DEFAULT.TXT" = {
      text = "FROM DEFAULT MODULE";
    };
  };
  
  # Import all submodules found in subdirectories
  imports = moduleImports;
}
{
  config,
  lib,
  ...
}: {
  # Import the module files
  imports = [
    ./blueman.nix
  ];
  
  # Create the top-level option structure
  options.cfg.bluetooth = lib.mkOption {
    type = lib.types.submodule {};
    default = {};
    description = "Bluetooth-related configuration for the user environment";
  };
}
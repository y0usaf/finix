{
  lib,
  whisper-overlay,
  ...
}: {
  imports = 
    # Import all directories with default.nix
    (import ../helpers/import-dirs.nix {inherit lib;}) ./. ++
    # Explicitly import the gaming module to ensure it's included
    [ ./gaming ];
}

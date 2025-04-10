{
  lib,
  whisper-overlay,
  ...
}: {
  imports = (import ../helpers/import-dirs.nix {inherit lib;}) ./.;
}

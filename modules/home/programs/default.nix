{
  lib,
  whisper-overlay,
  ...
}: {
  imports = (import ../../helpers/import-modules.nix {inherit lib;}) ./.;
}

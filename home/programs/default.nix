{lib, ...}: {
  imports = lib.importModules ./. ++ lib.importDirs ./.;
}

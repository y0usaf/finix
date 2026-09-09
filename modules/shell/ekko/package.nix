{
  lib,
  pkgs,
  flakeInputs,
  ...
}: {
  options.user.shell.ekko.package = lib.mkOption {
    type = lib.types.package;
    description = "Ekko runtime with upstream desktop defaults.";
    default = flakeInputs.ekko.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };
}

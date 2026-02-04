{
  pkgs,
  config,
  lib,
  ...
}: {
  config.environment.systemPackages =
    [
      pkgs.alejandra
      pkgs.statix
      pkgs.deadnix
    ]
    ++ lib.optionals config.boot.loader.limine.secureBoot.enable [
      pkgs.sbctl
    ];
}

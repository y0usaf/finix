{
  pkgs,
  lib,
  ...
}: {
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "obsidian" ''
      exec ${pkgs.obsidian}/bin/obsidian --force-device-scale-factor=1.5 "$@"
    '')
  ];
}

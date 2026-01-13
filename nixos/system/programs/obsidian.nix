{
  pkgs,
  config,
  ...
}: {
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "obsidian" ''
      exec ${pkgs.obsidian}/bin/obsidian --force-device-scale-factor=${builtins.toString config.user.ui.gtk.scale} "$@"
    '')
  ];
}

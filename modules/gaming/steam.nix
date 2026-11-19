{
  config,
  pkgs,
  ...
}: {
  user.persist.directories = [
    ".SteamCloud"
    ".steam"
  ];
  user.files."${config.user.paths.steam}/package/beta" = {
    type = "delete";
    force = false;
  };
  environment.systemPackages = [
    (
      if config.user.gaming.proton.enable
      then
        pkgs.steamWithMillennium.override {
          extraEnv.STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${pkgs.proton-ge-bin.steamcompattool}";
        }
      else pkgs.steamWithMillennium
    )
    pkgs.steam-run
  ];
  services.udev.packages = [
    (pkgs.runCommand "steam-devices-udev-rules-definit" {} ''
      mkdir -p $out/lib/udev/rules.d
      find ${pkgs.steam-devices-udev-rules}/ -type f -name "*.rules" | while read -r f; do
        ${pkgs.gnused}/bin/sed '/systemd/d' "$f" \
          > "$out/lib/udev/rules.d/$(basename "$f")"
      done
    '')
  ];
}

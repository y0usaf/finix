{
  config,
  lib,
  pkgs,
  ...
}: {
  user.persist.directories = [
    ".config/obsidian"
    ".obsidian"
  ];
  environment.systemPackages = [
    (pkgs.obsidian.override {
      commandLineArgs = lib.concatStringsSep " " [
        "--force-device-scale-factor=${builtins.toString config.user.ui.gtk.scale}"
        "--disable-smooth-scrolling"
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
      ];
    })
  ];
}

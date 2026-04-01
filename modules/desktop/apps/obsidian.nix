{
  config,
  pkgs,
  lib,
  ...
}: {
  options.user.programs.obsidian = {
    enable = lib.mkEnableOption "Obsidian module";
  };
  config = lib.mkIf config.user.programs.obsidian.enable {
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
  };
}

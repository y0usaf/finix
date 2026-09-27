{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.programs.obsidian = {
    enable = lib.mkEnableOption "Obsidian module";
  };
  config = lib.mkIf config.user.programs.obsidian.enable {
    finix.persistence.allowlist.users.${config.user.name}.directories = [
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
  };
}

{
  config,
  pkgs,
  lib,
  ...
}: {
  options.user.programs.obsidian = {
    enable = lib.mkEnableOption "Obsidian module";
    useWayland = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable Wayland/Ozone support for Obsidian";
    };
  };
  config = lib.mkIf config.user.programs.obsidian.enable {
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "obsidian" ''
        ${lib.optionalString config.user.programs.obsidian.useWayland ''
          export NIXOS_OZONE_WL=1
          export ELECTRON_OZONE_PLATFORM_HINT=wayland
        ''}
        exec ${pkgs.obsidian}/bin/obsidian \
          --disable-smooth-scrolling \
          --enable-gpu-rasterization \
          --enable-zero-copy \
          ${lib.optionalString config.user.programs.obsidian.useWayland "--ozone-platform-hint=wayland"} \
          "$@"
      '')
    ];
  };
}

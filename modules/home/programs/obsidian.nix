{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.programs.obsidian;
in {
  options.home.programs.obsidian = {
    enable = lib.mkEnableOption "Obsidian module";
    useWayland = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable Wayland/Ozone support for Obsidian";
    };
  };
  config = lib.mkIf cfg.enable {
    users.users.y0usaf.maid.packages = with pkgs; [
      (writeShellScriptBin "obsidian" ''
        ${lib.optionalString cfg.useWayland ''
          export NIXOS_OZONE_WL=1
          export ELECTRON_OZONE_PLATFORM_HINT=wayland
        ''}
        exec ${obsidian}/bin/obsidian \
          --disable-smooth-scrolling \
          --enable-gpu-rasterization \
          --enable-zero-copy \
          ${lib.optionalString cfg.useWayland "--ozone-platform-hint=wayland"} \
          "$@"
      '')
    ];
  };
}

{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  codex-desktop = flakeInputs.codex-desktop-linux.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  options.user.programs.codex-desktop = {
    enable = lib.mkEnableOption "Codex Desktop (OpenAI Codex app for Linux)";
    useWayland = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable Wayland/Ozone support for Codex Desktop";
    };
  };

  config = lib.mkIf config.user.programs.codex-desktop.enable {
    environment.systemPackages = [
      codex-desktop
      (pkgs.writeShellScriptBin "codex-desktop-launcher" ''
        ${lib.optionalString config.user.programs.codex-desktop.useWayland ''
          export NIXOS_OZONE_WL=1
          export ELECTRON_OZONE_PLATFORM_HINT=wayland
        ''}
        exec ${codex-desktop}/bin/codex-desktop "$@"
      '')
    ];
  };
}

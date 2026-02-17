{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  cfg = config.user.programs.codex-desktop;
  codex-desktop = flakeInputs.codex-desktop-linux.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  options.user.programs.codex-desktop = {
    enable = lib.mkEnableOption "Codex Desktop (OpenAI Codex app for Linux)";
    useWayland = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable Wayland/Ozone support for Codex Desktop";
    };
    yoloMode = lib.mkEnableOption ''
      Codex full access mode (no permission prompts) by forcing approval_policy=never and
      sandbox_mode=danger-full-access in Codex config.toml
    '';
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      codex-desktop
      (pkgs.writeShellScriptBin "codex-desktop-launcher" ''
        ${lib.optionalString cfg.useWayland ''
          export NIXOS_OZONE_WL=1
          export ELECTRON_OZONE_PLATFORM_HINT=wayland
        ''}
        exec ${codex-desktop}/bin/codex-desktop "$@"
      '')
    ];

    user.dev.codex = lib.mkIf cfg.yoloMode {
      enable = lib.mkDefault true;
      settings.approval_policy = lib.mkForce "never";
      settings.sandbox_mode = lib.mkForce "danger-full-access";
    };
  };
}

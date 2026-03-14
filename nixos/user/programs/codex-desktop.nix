{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkForce;
  codexDesktopCfg = config.user.programs.codex-desktop;
  codex-desktop = flakeInputs.codex-desktop-linux.packages."${pkgs.stdenv.hostPlatform.system}".default.overrideAttrs (_: {
    src = pkgs.fetchurl {
      url = "https://persistent.oaistatic.com/codex-app-prod/Codex.dmg";
      hash = "sha256-4oKdhkRmwUbvnexeguuwfv+oRHhR3WYbUwewB9rpLDc=";
    };
  });
in {
  options.user.programs.codex-desktop = {
    enable = mkEnableOption "Codex Desktop (OpenAI Codex app for Linux)";
    useWayland = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable Wayland/Ozone support for Codex Desktop";
    };
    yoloMode = mkEnableOption ''
      Codex full access mode (no permission prompts) by forcing approval_policy=never and
      sandbox_mode=danger-full-access in Codex config.toml
    '';
  };

  config = mkIf codexDesktopCfg.enable {
    environment.systemPackages = [
      codex-desktop
      (pkgs.writeShellScriptBin "codex-desktop-launcher" ''
        ${lib.optionalString codexDesktopCfg.useWayland ''
          export NIXOS_OZONE_WL=1
          export ELECTRON_OZONE_PLATFORM_HINT=wayland
        ''}
        exec ${codex-desktop}/bin/codex-desktop "$@"
      '')
    ];

    user.dev.codex = mkIf codexDesktopCfg.yoloMode {
      enable = lib.mkDefault true;
      settings.approval_policy = mkForce "never";
      settings.sandbox_mode = mkForce "danger-full-access";
    };
  };
}

{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  codexDesktopCfg = config.user.programs.codex-desktop;
  codex-desktop = (pkgs.callPackage "${flakeInputs.codex-desktop-linux}/package.nix" {}).overrideAttrs {
    # Upstream Codex.dmg is a mutable URL AND upstream (2026-07) renamed
    # Codex.app → ChatGPT.app inside the DMG, which package.nix can't find.
    # Pin to the last known-good June 2026 DMG (still in local /nix/store).
    src = pkgs.fetchurl {
      url = "https://persistent.oaistatic.com/codex-app-prod/Codex.dmg";
      hash = "sha256-xGhTgxNq/IhSbFhBu4Sie2BxkOzqEeaPSeSTQce/34o=";
    };
  };
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
  };
}

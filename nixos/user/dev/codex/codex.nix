{
  config,
  lib,
  pkgs,
  ...
}: let
  codexConfig = import ../../../../lib/codex;
in {
  options.user.dev.codex = {
    enable = lib.mkEnableOption "Codex CLI configuration and instructions";

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = codexConfig.settings;
      description = "Codex CLI config.toml settings.";
    };
  };

  config = lib.mkIf config.user.dev.codex.enable {
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "codex" ''
        exec ${pkgs.bun}/bin/bunx --bun @openai/codex "$@"
      '')
    ];
  };
}

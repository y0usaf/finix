{
  config,
  lib,
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

  config = lib.mkIf config.user.dev.codex.enable {};
}

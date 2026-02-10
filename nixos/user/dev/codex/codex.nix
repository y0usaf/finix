{
  config,
  lib,
  ...
}: let
  codexConfig = import ../../../../lib/codex;
in {
  options.user.dev.codex = {
    enable = lib.mkEnableOption "Codex CLI configuration and instructions";

    model = lib.mkOption {
      type = lib.types.str;
      default = "gpt-5.3-codex";
      description = "Codex model to use";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = codexConfig.settings;
      description = "Codex CLI config.toml settings.";
    };
  };

  config = lib.mkIf config.user.dev.codex.enable {};
}

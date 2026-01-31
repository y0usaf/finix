{
  config,
  lib,
  ...
}: {
  options.user.dev.codex = {
    enable = lib.mkEnableOption "Codex CLI configuration and instructions";
  };

  config = lib.mkIf config.user.dev.codex.enable {};
}

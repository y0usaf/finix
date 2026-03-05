{
  config,
  lib,
  genLib,
  ...
}: let
  codexConfig = import ../../../../lib/codex;
in {
  config = lib.mkIf config.user.dev.codex.enable {
    usr.files = {
      ".codex/agents/explorer.toml" = {
        generator = genLib.toTOML;
        value = codexConfig.agents.explorer;
        clobber = true;
      };
      ".codex/agents/worker.toml" = {
        generator = genLib.toTOML;
        value = codexConfig.agents.worker;
        clobber = true;
      };
    };
  };
}

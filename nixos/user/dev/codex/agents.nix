{
  config,
  lib,
  genLib,
  ...
}: {
  config = lib.mkIf config.user.dev.codex.enable {
    usr.files = {
      ".codex/agents/explorer.toml" = {
        generator = genLib.toTOML;
        value = (import ../../../../lib/codex).agents.explorer;
        clobber = true;
      };
      ".codex/agents/worker.toml" = {
        generator = genLib.toTOML;
        value = (import ../../../../lib/codex).agents.worker;
        clobber = true;
      };
    };
  };
}

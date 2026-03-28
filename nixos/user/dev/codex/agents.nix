{
  config,
  lib,
  genLib,
  ...
}: {
  config = lib.mkIf config.user.dev.codex.enable {
    bayt.users."${config.user.name}".files = {
      ".codex/agents/explorer.toml" = {
        generator = genLib.toTOML;
        value = (import ./data).agents.explorer;
        clobber = true;
      };
      ".codex/agents/worker.toml" = {
        generator = genLib.toTOML;
        value = (import ./data).agents.worker;
        clobber = true;
      };
    };
  };
}

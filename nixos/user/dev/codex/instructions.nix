{
  config,
  lib,
  genLib,
  ...
}: {
  config = lib.mkIf config.user.dev.codex.enable {
    bayt.users."${config.user.name}".files = {
      ".codex/INSTRUCTIONS.md" = {
        text = (import ./data).instructions;
        clobber = true;
      };
      ".codex/config.toml" = {
        generator = genLib.toTOML;
        value =
          (import ./data).settings
          // config.user.dev.codex.settings
          // {
            inherit (config.user.dev.codex) model;
          };
        clobber = true;
      };
    };
  };
}

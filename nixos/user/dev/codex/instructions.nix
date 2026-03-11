{
  config,
  lib,
  genLib,
  ...
}: {
  config = lib.mkIf config.user.dev.codex.enable {
    usr.files = {
      ".codex/INSTRUCTIONS.md" = {
        text = (import ../../../../lib/codex).instructions;
        clobber = true;
      };
      ".codex/config.toml" = {
        generator = genLib.toTOML;
        value =
          (import ../../../../lib/codex).settings
          // config.user.dev.codex.settings
          // {
            inherit (config.user.dev.codex) model;
          };
        clobber = true;
      };
    };
  };
}

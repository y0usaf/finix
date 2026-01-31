{
  config,
  lib,
  ...
}: let
  codexConfig = import ../../../../lib/codex;
in {
  config = lib.mkIf config.user.dev.codex.enable {
    usr.files = {
      ".codex/INSTRUCTIONS.md" = {
        text = codexConfig.instructions;
        clobber = true;
      };
    };
  };
}

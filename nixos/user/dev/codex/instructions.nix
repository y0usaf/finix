{
  config,
  lib,
  pkgs,
  ...
}: let
  codexConfig = import ../../../../lib/codex;
  tomlFormat = pkgs.formats.toml {};
  tomlGenerator =
    if lib.generators ? toTOML
    then lib.generators.toTOML {}
    else (value: builtins.readFile (tomlFormat.generate "codex-config" value));
in {
  config = lib.mkIf config.user.dev.codex.enable {
    usr.files = {
      ".codex/INSTRUCTIONS.md" = {
        text = codexConfig.instructions;
        clobber = true;
      };
      ".codex/config.toml" = {
        generator = tomlGenerator;
        value =
          config.user.dev.codex.settings
          // {
            inherit (config.user.dev.codex) model;
          };
        clobber = true;
      };
    };
  };
}

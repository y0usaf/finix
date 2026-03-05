{
  lib,
  pkgs,
}: let
  tomlFormat = pkgs.formats.toml {};
in {
  toTOML = value: builtins.readFile (tomlFormat.generate "codex-toml" value);
}

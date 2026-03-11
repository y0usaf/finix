{
  lib,
  pkgs,
}: {
  toTOML = value: builtins.readFile ((pkgs.formats.toml {}).generate "codex-toml" value);
}

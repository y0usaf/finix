{pkgs, ...}: {
  config.lib.generators.toTOML = value: builtins.readFile ((pkgs.formats.toml {}).generate "codex-toml" value);
}

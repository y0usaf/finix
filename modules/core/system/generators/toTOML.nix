{pkgs, ...}: {
  config.lib.generators.toTOML = value: (pkgs.formats.toml {}).generate "nix-generated.toml" value;
}

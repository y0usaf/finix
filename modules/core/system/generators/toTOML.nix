{pkgs, ...}: {
  # Keep generated TOML as a store path. Reading it here forces a derivation build during eval.
  config.lib.generators.toTOML = value: (pkgs.formats.toml {}).generate "nix-generated.toml" value;
}

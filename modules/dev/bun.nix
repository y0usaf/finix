{
  config,
  pkgs,
  ...
}: {
  user.persist.directories = [".local/share/bun"];
  environment.systemPackages = [pkgs.bun];
  user.files.".config/bun/bunfig.toml" = {
    generator = (pkgs.formats.toml {}).generate "nix-generated.toml";
    value.install = {
      cache_dir = "${config.user.homeDirectory}/.cache/bun";
      global_dir = "${config.user.homeDirectory}/.local/share/bun";
    };
  };
}

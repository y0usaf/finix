{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.dev.biome = {
    enable = lib.mkEnableOption "Biome linter with anti-slop rules";
  };
  config = lib.mkIf config.user.dev.biome.enable {
    environment.systemPackages = [
      pkgs.biome
    ];
    # Global default config lives at $HOME/.config/biome/biome.json. No kualta
    # GritQL plugin: it would need a node_modules tree; native biome rules cover
    # the anti-slop moves globally from the home config with zero node deps.
    manzil.users."${config.user.name}".files.".config/biome/biome.json" = {
      generator = lib.generators.toJSON {};
      value = {
        "$schema" = "https://biomejs.dev/schemas/2.5.5/schema.json";
        files.ignoreUnknown = true;
        formatter.enabled = false;
        assist.enabled = false;
        linter = {
          enabled = true;
          rules = {
            recommended = false;
            suspicious = {
              noExplicitAny = "error";
              noImplicitAnyLet = "error";
              noConfusingVoidType = "error";
              noTsIgnore = "error";
            };
            style.noNonNullAssertion = "error";
            correctness.noUnusedImports = "error";
          };
        };
      };
    };
  };
}

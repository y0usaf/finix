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

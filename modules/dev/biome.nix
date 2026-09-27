{
  config,
  lib,
  pkgs,
  ...
}: {
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
}

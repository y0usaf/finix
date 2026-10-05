{
  config,
  lib,
  ...
}: {
  manzil.users."${config.user.name}".files.".local/state/honey/agent/settings.json" = {
    generator = lib.generators.toJSON {};
    value = {
      defaultTools = ["+codemode"];
      codemode.mode = "only";
    };
  };
}

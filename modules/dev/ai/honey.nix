{
  config,
  lib,
  ...
}: {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".local/state/honey"
  ];
  manzil.users."${config.user.name}".files.".local/state/honey/agent/settings.json" = {
    generator = lib.generators.toJSON {};
    value = {
      defaultTools = ["+codemode"];
      codemode.mode = "only";
    };
  };
}

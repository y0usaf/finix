{
  config,
  lib,
  ...
}: {
  options.user.dev.ai.hermes.apiKeyFile = lib.mkOption {
    type = lib.types.str;
    default = "${config.users.users.${config.user.name}.home}/Tokens/AI_GATEWAY_API_KEY.txt";
    description = "Optional runtime AI Gateway secret file; contents never enter the store.";
  };
}

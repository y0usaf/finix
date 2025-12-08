{
  config,
  lib,
  ...
}: let
  models = import ./models.nix;
  # Try to load host-specific environment, fall back to default
  hostEnv = "environment-${config.networking.hostName}.nix";
  environment =
    if builtins.pathExists ./${hostEnv}
    then import ./${hostEnv}
    else import ./environment-default.nix;
  gpuAcceleration = import ./gpu.nix;
in {
  options.user.dev.localllama = {
    enable = lib.mkEnableOption "Local LLM setup with Ollama";
  };

  config = lib.mkIf config.user.dev.localllama.enable {
    services.ollama =
      {
        enable = true;
        host = "127.0.0.1";
        port = 11434;

        loadModels = models;
        environmentVariables = environment;
      }
      // lib.optionalAttrs (gpuAcceleration != null) {
        acceleration = gpuAcceleration;
      };
  };
}

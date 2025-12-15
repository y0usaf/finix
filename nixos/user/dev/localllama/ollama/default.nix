{
  config,
  lib,
  pkgs,
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

  # Map GPU acceleration type to ollama package variant
  ollamaPackage =
    if gpuAcceleration == "cuda"
    then pkgs.ollama-cuda
    else if gpuAcceleration == "rocm"
    then pkgs.ollama-rocm
    else if gpuAcceleration == "vulkan"
    then pkgs.ollama-vulkan
    else if gpuAcceleration == null
    then pkgs.ollama-cpu
    else pkgs.ollama;
in {
  options.user.dev.localllama = {
    enable = lib.mkEnableOption "Local LLM setup with Ollama";
  };

  config = lib.mkIf config.user.dev.localllama.enable {
    services.ollama = {
      enable = true;
      package = ollamaPackage;
      host = "127.0.0.1";
      port = 11434;

      loadModels = models;
      environmentVariables = environment;
    };
  };
}

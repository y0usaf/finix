{
  config,
  lib,
  pkgs,
  ...
}: let
  ollama = import ../../../../lib/ai/ollama.nix;
  gpuAcceleration = import ./data/gpu-acceleration.nix;
  environmentVariables =
    {
      "y0usaf-desktop" = import ./data/environment-y0usaf-desktop.nix;
    }
    .${
      config.networking.hostName
    }
    or (import
      ./data/environment-default.nix);
  # Map GPU acceleration type to ollama package variant
in {
  options.user.dev.localllama = {
    enable = lib.mkEnableOption "Local LLM setup with Ollama";
  };

  config = lib.mkIf config.user.dev.localllama.enable {
    services.ollama = {
      enable = true;
      package =
        if gpuAcceleration == "cuda"
        then pkgs.ollama-cuda
        else if gpuAcceleration == "rocm"
        then pkgs.ollama-rocm
        else if gpuAcceleration == "vulkan"
        then pkgs.ollama-vulkan
        else if gpuAcceleration == null
        then pkgs.ollama-cpu
        else pkgs.ollama;
      host = "127.0.0.1";
      port = 11434;

      loadModels = ollama.preloadModels;
      inherit environmentVariables;
    };
  };
}

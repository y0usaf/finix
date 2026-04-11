{
  config,
  lib,
  pkgs,
  ...
}: let
  # GPU acceleration settings for Ollama
  # Options: null (CPU only), "cuda" (NVIDIA), "rocm" (AMD), etc.
  # "cuda" for NVIDIA GPUs like RTX 4090
  gpuAcceleration = "cuda";

  # Default fallback environment settings for systems without specific tuning
  # Conservative settings that work on most hardware
  environmentDefault = {
    OLLAMA_NUM_PARALLEL = "4";
    OLLAMA_NUM_THREAD = "8";
  };

  # Optimized for RTX 4090 + Ryzen 7950X (y0usaf-desktop)
  # Single model performance focus: maximize GPU utilization, use full CPU capacity
  environmentY0usafDesktop = {
    # Single model focus - handle one request at a time for best quality
    OLLAMA_NUM_PARALLEL = "1";
    # Use 16 threads (half of 7950X's 32 threads) to avoid oversubscription
    # Let the OS handle other system tasks
    OLLAMA_NUM_THREAD = "16";
    # Maximize GPU layer offloading to 4090's 24GB VRAM
    # Use high value to fit entire model on GPU when possible
    OLLAMA_NUM_GPU_LAYERS = "999";
    # Keep model in memory for 5 minutes after last use
    # Faster reload when switching models
    OLLAMA_KEEP_ALIVE = "5m";
    # Use more memory for better performance (4090 can handle it)
    # Adjust if you want stricter memory limits
    OLLAMA_MAX_VRAM = "24000000000"; # ~24GB in bytes
    # For Mixture-of-Experts models (deepseek-coder-v2, qwq)
    # Keep expert weights on CPU, offload only active experts to GPU
    # Enables running larger MoE models like 16B, 32B on 4090
    OLLAMA_CPU_MOE = "1";
  };

  environmentVariables =
    {
      "y0usaf-desktop" = environmentY0usafDesktop;
    }
    ."${
      config.networking.hostName
    }"
    or environmentDefault;
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

      loadModels = [
        "deepseek-coder-v2:16b"
        "qwen2.5-coder:32b"
        "qwq:32b"
        "qwen2.5:32b"
      ];
      inherit environmentVariables;
    };
  };
}

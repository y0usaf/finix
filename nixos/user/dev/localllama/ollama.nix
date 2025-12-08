{
  config,
  pkgs,
  lib,
  ...
}: {
  options.user.dev.localllama = {
    enable = lib.mkEnableOption "Local LLM setup with Ollama";
  };
  config = lib.mkIf config.user.dev.localllama.enable {
    services.ollama = {
      enable = true;
      host = "127.0.0.1";
      port = 11434;

      # Pre-download models optimized for 24GB VRAM
      loadModels = [
        "llama3.2:3b" # Fast baseline model
        "qwen2.5:7b" # Excellent Chinese support + multilingual
        "nomic-embed-text" # Embeddings for RAG workflows
      ];

      # Optional: uncomment to auto-remove models not in loadModels
      # syncModels = true;

      environmentVariables = {
        # Tune for your system
        OLLAMA_NUM_PARALLEL = "4";
        OLLAMA_NUM_THREAD = "8";
      };
    };
  };
}

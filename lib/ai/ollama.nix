{
  preloadModels = [
    "deepseek-coder-v2:16b"
    "qwen2.5-coder:32b"
    "qwq:32b"
    "qwen2.5:32b"
  ];

  providerModels = {
    "deepseek-coder-v2:16b" = {
      name = "DeepSeek Coder V2 (16B MoE)";
      description = "Excellent code reasoning, MoE with --cpu-moe optimization";
    };
    "qwen2.5-coder:32b" = {
      name = "Qwen 2.5 Coder (32B)";
      description = "State-of-the-art code generation and understanding";
    };
    "qwq:32b" = {
      name = "QwQ (32B Reasoning)";
      description = "DeepSeek's reasoning-specialized model for complex problems";
    };
    "qwen2.5:32b" = {
      name = "Qwen 2.5 (32B)";
      description = "Excellent multilingual and general-purpose capabilities";
    };
    "nomic-embed-text:latest" = {
      name = "Nomic Embed Text";
      description = "Embeddings for RAG workflows";
    };
  };
}

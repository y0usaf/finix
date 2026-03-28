# OpenCode Ollama provider configuration
# System-agnostic setup for local LLM access via OpenCode
{
  "$schema" = "https://opencode.ai/config.json";
  "provider" = {
    "ollama" = {
      "npm" = "@ai-sdk/openai-compatible";
      "name" = "Ollama (local)";
      "options" = {
        "baseURL" = "http://localhost:11434/v1";
      };
      "models" = {
        # Coding specialists
        "deepseek-coder-v2:16b" = {
          "name" = "DeepSeek Coder V2 (16B MoE)";
          "description" = "Excellent code reasoning, MoE with --cpu-moe optimization";
        };
        "qwen2.5-coder:32b" = {
          "name" = "Qwen 2.5 Coder (32B)";
          "description" = "State-of-the-art code generation and understanding";
        };

        # Reasoning specialist
        "qwq:32b" = {
          "name" = "QwQ (32B Reasoning)";
          "description" = "DeepSeek's reasoning-specialized model for complex problems";
        };

        # General purpose
        "qwen2.5:32b" = {
          "name" = "Qwen 2.5 (32B)";
          "description" = "Excellent multilingual and general-purpose capabilities";
        };

        # Utilities
        "nomic-embed-text:latest" = {
          "name" = "Nomic Embed Text";
          "description" = "Embeddings for RAG workflows";
        };
      };
    };
  };
}

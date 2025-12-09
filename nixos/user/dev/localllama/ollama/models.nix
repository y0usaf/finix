# Model registry - models to pre-download and make available
# Optimized for 4090 + 96GB RAM
[
  # Coding-focused models
  "deepseek-coder-v2:16b" # Excellent reasoning + code, MoE with cpu-moe optimization
  "qwen2.5-coder:32b" # State-of-the-art code quality, dense model

  # Reasoning model
  "qwq:32b" # DeepSeek's reasoning specialist

  # General purpose fallback
  "qwen2.5:32b" # Multilingual, excellent general purpose
]

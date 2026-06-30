_: {
  user.dev = {
    claude-code = {
      enable = true;
      model = "sonnet";
      subagentModel = "sonnet";
      enabledPlugins."audio-notify@y0usaf-marketplace" = false;
      providers."vercel-ai-gateway" = {
        enable = true;
        apiKeyFile = "/home/y0usaf/Tokens/AI_GATEWAY_API_KEY.txt";
        models = {
          ANTHROPIC_DEFAULT_OPUS_MODEL = "zai/glm-5.2-fast";
          ANTHROPIC_DEFAULT_SONNET_MODEL = "zai/glm-5.2-fast";
          ANTHROPIC_DEFAULT_HAIKU_MODEL = "zai/glm-5.2-fast";
        };
        extraEnv.CLAUDE_CODE_AUTO_COMPACT_WINDOW = "1000000";
      };
    };
    codex = {
      enable = true;
      model = "zai/glm-5.2-fast";
      providers."vercel-ai-gateway" = {
        enable = true;
        apiKeyFile = "/home/y0usaf/Tokens/AI_GATEWAY_API_KEY.txt";
      };
      settings.personality = "pragmatic";
    };
    android-tools.enable = true;
    codex-cli.enable = true;
    crush.enable = true;
    work = {
      agent-slack.enable = true;
      gws.enable = true;
      linear-cli.enable = true;
    };
    pi.enable = true;
    docker.enable = true;
    gcloud.enable = true;
    localllama.enable = false;
    nvim.enable = true;
    bun.enable = true;
    python.enable = true;
    rust.enable = true;
    opencode = {
      enable = true;
      enableMcpServers = false;
    };
    latex.enable = true;
    upscale.enable = true;
  };
}

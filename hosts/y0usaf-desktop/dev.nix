_: {
  user.dev = {
    kimi-code = {
      enable = true;
      apiKeyFile = "/home/y0usaf/Tokens/AI_GATEWAY_API_KEY.txt";
    };
    claude-code = {
      enable = true;
      model = "fable";
      subagentModel = "claude-sonnet-5";
      enabledPlugins."audio-notify@y0usaf-marketplace" = false;
      providers.vercel = {
        baseUrl = "https://ai-gateway.vercel.sh";
        apiKeyFile = "/home/y0usaf/Tokens/AI_GATEWAY_API_KEY.txt";
        models = {
          ANTHROPIC_DEFAULT_OPUS_MODEL = "moonshotai/kimi-k3-fast";
          ANTHROPIC_DEFAULT_SONNET_MODEL = "moonshotai/kimi-k3-fast";
          ANTHROPIC_DEFAULT_HAIKU_MODEL = "moonshotai/kimi-k3-fast";
        };
      };
    };
    codex.enable = true;
    android-tools.enable = true;
    codex-cli.enable = true;
    crush.enable = true;
    work = {
      agent-slack.enable = true;
      gws.enable = true;
      linear-cli.enable = true;
    };
    pi.enable = true;
    canon.enable = true;
    docker.enable = true;
    gcloud.enable = true;
    localllama.enable = false;
    nvim.enable = true;
    bun.enable = true;
    npm.enable = true;
    python.enable = true;
    rust.enable = true;
    opencode = {
      enable = true;
      enableMcpServers = false;
    };
    latex.enable = true;
    upscale.enable = true;
    phi.enable = true;
  };
}

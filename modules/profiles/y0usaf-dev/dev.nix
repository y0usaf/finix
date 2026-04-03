_: {
  user.dev = {
    claude-code = {
      enable = true;
      model = "sonnet";
      subagentModel = "sonnet";
    };
    codex = {
      enable = true;
      model = "gpt-5.4";
      settings.personality = "pragmatic";
    };
    android-tools.enable = true;
    codex-cli.enable = true;
    crush.enable = true;
    gemini-cli.enable = false;
    agent-slack.enable = true;
    pi.enable = true;
    mcp.enable = false;
    docker.enable = true;
    gcloud.enable = true;
    localllama.enable = false;
    nvim = {
      enable = true;
      neovide = false;
    };
    python.enable = true;
    rust.enable = true;
    opencode = {
      enable = true;
      enableMcpServers = false;
    };
    latex.enable = false;
    upscale.enable = false;
  };
}

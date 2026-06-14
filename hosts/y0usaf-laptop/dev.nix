_: {
  user.dev = {
    claude-code = {
      enable = true;
      model = "sonnet";
      subagentModel = "sonnet";
      enabledPlugins."audio-notify@y0usaf-marketplace" = false;
    };
    codex = {
      enable = true;
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
    localllama.enable = true;
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

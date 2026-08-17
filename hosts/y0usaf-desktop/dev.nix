_: {
  user.dev = {
    kimi-code = {
      enable = true;
      apiKeyFile = "/home/y0usaf/Tokens/AI_GATEWAY_API_KEY.txt";
    };
    claude-code.enable = true;
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
    pi.agents = {
      maxDepth = 999;
      maxLiveAgents = 999;
    };
    paseo = {
      enable = true;
      reasonix.enable = false;
      # Seed the Vercel AI Gateway key into the paseo daemon env so the agent
      # children it spawns (pi) can resolve the vercel-ai-gateway provider.
      # Basename AI_GATEWAY_API_KEY.txt -> AI_GATEWAY_API_KEY (mirrors the
      # server's ANTHROPIC_API_KEY wiring in hosts/y0usaf-server/finix/paseo.nix).
      environmentFiles = [
        "/home/y0usaf/Tokens/AI_GATEWAY_API_KEY.txt"
      ];
      # desktop y0usaf's primary group is `users` (no y0usaf group), same as the
      # server — without this finit can't fork the daemon
      group = "users";
    };
    principles.enable = true;
    docker.enable = true;
    gcloud.enable = true;
    nvim.enable = true;
    bun.enable = true;
    biome.enable = true;
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
    prime-agent.enable = true;
    reasonix = {
      enable = true;
      apiKeyFile = "/home/y0usaf/Tokens/AI_GATEWAY_API_KEY.txt";
    };
  };
}

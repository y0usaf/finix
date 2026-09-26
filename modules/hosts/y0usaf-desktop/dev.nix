_: {
  user.dev = {
    autolith.enable = true;
    claude-code.enable = true;
    codex.enable = true;
    android-tools.enable = true;
    crush.enable = true;
    fx.enable = true;
    work = {
      aws-cli.enable = true;
      gws.enable = true;
      linear-cli.enable = true;
      ntn.enable = true;
      ramp.enable = true;
      vercel.enable = true;
    };
    ai = {
      agent-slack.enable = true;
      firstmate.enable = true;
    };
    pi = {
      enable = true;
      agents = {
        maxDepth = 999;
        maxLiveAgents = 999;
      };
    };
    prime-agent.enable = true;
    prompts.principles.enable = true;
    omp = {
      enable = true;
      settings = {
        terminal_width_percent = 50;
        panel_width_percent = 13;
        ascii = true;
        keybinds = {
          project_next = "ctrl+l";
          project_prev = "ctrl+h";
          session_next = "ctrl+j";
          session_prev = "ctrl+k";
        };
      };
      ttsrRules.tldr = {
        minOutputLength = 2000;
        scope = "text";
        interruptMode = "never";
        content = "TL;DR: summarize the preceding response in 3-5 concise bullets.";
      };
    };
    paseo = {
      enable = true;
      desktop.enable = true;
      reasonix.enable = false;
      environmentFiles = [
        "/home/y0usaf/Tokens/AI_GATEWAY_API_KEY.txt"
      ];
      group = "users";
    };
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
    r2t2.enable = true;
    phi.enable = true;
    reasonix = {
      enable = true;
      apiKeyFile = "/home/y0usaf/Tokens/AI_GATEWAY_API_KEY.txt";
    };
  };
}

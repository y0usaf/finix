_: {
  user.dev = {
    kimi-code = {
      enable = true;
      apiKeyFile = "/home/y0usaf/Tokens/AI_GATEWAY_API_KEY.txt";
    };
    claude-code.enable = true;
    codex.enable = true;
    android-tools.enable = true;
    crush.enable = true;
    fx.enable = true;
    work = {
      agent-slack.enable = true;
      aws-cli.enable = true;
      gws.enable = true;
      linear-cli.enable = true;
      notion-cli.enable = true;
      ramp.enable = true;
      vercel.enable = true;
    };
    pi = {
      enable = true;
      agents = {
        maxDepth = 999;
        maxLiveAgents = 999;
      };
    };
    prime-agent.enable = true;
    omp = {
      enable = true;
      # Harness surface (~/.omp/config.json), mirroring the live
      # ~/.pi/config.json values. pi-only keys dropped — no omp equivalent:
      # pi_binary (discovery uses $OMP_BINARY / which("omp")), tui_mode (flag
      # removed upstream), ui_scale, panel_padding_cells, font_family,
      # body_height_percent (all ignored by omp's AppConfig).
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
      # GUI companion to the daemon (Electron wrapper around the Paseo web UI).
      desktop.enable = true;
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
    reasonix = {
      enable = true;
      apiKeyFile = "/home/y0usaf/Tokens/AI_GATEWAY_API_KEY.txt";
    };
  };
}

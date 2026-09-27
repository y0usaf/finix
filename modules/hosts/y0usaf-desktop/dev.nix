_: {
  user.dev = {
    work = {
      aws-cli.enable = true;
      ntn.enable = true;
      ramp.enable = true;
      vercel.enable = true;
    };
    ai.firstmate.enable = true;
    pi.agents = {
      maxDepth = 999;
      maxLiveAgents = 999;
    };
    prime-agent.enable = true;
    prompts.principles.enable = true;
    omp.settings = {
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
    paseo = {
      enable = true;
      desktop.enable = true;
      environmentFiles = [
        "/home/y0usaf/Tokens/AI_GATEWAY_API_KEY.txt"
      ];
      group = "users";
    };
    biome.enable = true;
    latex.enable = true;
    upscale.enable = true;
    r2t2.enable = true;
    phi.enable = true;
    reasonix.enable = true;
  };

  manzil.users.y0usaf.files.".omp/agent/rules/tldr.md".text = ''
    ---
    {"condition":["(?s).{2000,}"],"interruptMode":"never","scope":"text"}---

    TL;DR: summarize the preceding response in 3-5 concise bullets.
  '';
}

{lib, ...}: {
  user.dev = {
    autolith.enable = lib.mkDefault true;
    claude-code.enable = lib.mkDefault true;
    codex.enable = lib.mkDefault true;
    devin.enable = lib.mkDefault true;
    android-tools.enable = lib.mkDefault true;
    crush.enable = lib.mkDefault true;
    fx.enable = lib.mkDefault true;
    work = {
      gws.enable = lib.mkDefault true;
      linear-cli.enable = lib.mkDefault true;
      aws-cli.enable = lib.mkDefault true;
      ntn.enable = lib.mkDefault true;
      ramp.enable = lib.mkDefault true;
      vercel.enable = lib.mkDefault true;
    };
    ai.agent-slack.enable = lib.mkDefault true;
    ai.firstmate.enable = lib.mkDefault true;
    pi.enable = lib.mkDefault true;
    prime-agent.enable = lib.mkDefault true;
    prompts.principles.enable = lib.mkDefault true;
    paseo = {
      enable = lib.mkDefault true;
      desktop.enable = lib.mkDefault true;
      environmentFiles = ["/home/y0usaf/Tokens/AI_GATEWAY_API_KEY.txt"];
    };
    rtk.enable = lib.mkDefault true;
    omp.enable = lib.mkDefault true;
    bun.enable = lib.mkDefault true;
    biome.enable = lib.mkDefault true;
    latex.enable = lib.mkDefault true;
    npm.enable = lib.mkDefault true;
    docker.enable = lib.mkDefault true;
    gcloud.enable = lib.mkDefault true;
    nvim.enable = lib.mkDefault true;
    python.enable = lib.mkDefault true;
    rust.enable = lib.mkDefault true;
    opencode.enable = lib.mkDefault true;
  };
}

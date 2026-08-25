{lib, ...}: {
  user.dev = {
    claude-code.enable = lib.mkDefault true;
    codex.enable = lib.mkDefault true;
    android-tools.enable = lib.mkDefault true;
    crush.enable = lib.mkDefault true;
    fx.enable = lib.mkDefault true;
    work = {
      agent-slack.enable = lib.mkDefault true;
      gws.enable = lib.mkDefault true;
      linear-cli.enable = lib.mkDefault true;
    };
    pi.enable = lib.mkDefault true;
    rtk.enable = lib.mkDefault true;
    omp.enable = lib.mkDefault true;
    bun.enable = lib.mkDefault true;
    npm.enable = lib.mkDefault true;
    docker.enable = lib.mkDefault true;
    gcloud.enable = lib.mkDefault true;
    nvim.enable = lib.mkDefault true;
    python.enable = lib.mkDefault true;
    rust.enable = lib.mkDefault true;
    opencode = {
      enable = lib.mkDefault true;
      enableMcpServers = lib.mkDefault false;
    };
  };
}

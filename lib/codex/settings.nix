{
  approval_policy = "never";
  sandbox_mode = "danger-full-access";
  features = {
    multi_agent = true;
    steer = true;
    unified_exec = true;
  };
  otel = {
    exporter = "none";
    log_user_prompt = false;
    environment = "dev";
  };
  tui = {
    alternate_screen = "never";
  };
  mcp_servers = {
    linear = {
      command = "bunx";
      args = ["--bun" "@tacticlaunch/mcp-linear"];
      env_vars = ["LINEAR_API_KEY"];
    };
  };
}

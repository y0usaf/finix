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
  agents = {
    explorer = {
      description = "Use for codebase discovery and analysis. Prioritize reading, tracing, and precise explanations before making edits.";
      config_file = "./agents/explorer.toml";
    };
    worker = {
      description = "Use for implementation and execution tasks. Make targeted changes, run checks, and return concrete results.";
      config_file = "./agents/worker.toml";
    };
  };
}

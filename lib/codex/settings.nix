{
  approval_policy = "never";
  sandbox_mode = "danger-full-access";
  features = {
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
}

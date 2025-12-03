# parallelization-instruct plugin - Parallel tool call reminders
{
  name = "parallelization-instruct";
  version = "1.0.0";
  description = "Reminders to parallelize independent tool calls";
  author = {
    name = "y0usaf";
  };

  hooks = import ./hooks.nix;
}

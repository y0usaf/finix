# agent-slack plugin - exposes the local agent-slack CLI as a Claude Code skill
{
  name = "agent-slack";
  version = "1.0.0";
  description = "Expose the local agent-slack CLI as an installable skill";
  author = {
    name = "y0usaf";
  };

  skills = {
    agent-slack = import ../../../../codex/data/skills/agent-slack.nix;
  };
}

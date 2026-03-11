# linear-cli plugin - exposes the schpet Linear CLI as a Claude Code skill
{
  name = "linear-cli";
  version = "1.0.0";
  description = "Expose the schpet Linear CLI via bunx as an installable skill";
  author = {
    name = "y0usaf";
  };

  skills = {
    linear-cli = import ../../../codex/skills/linear-cli.nix;
  };
}

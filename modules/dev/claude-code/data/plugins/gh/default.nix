# gh plugin - exposes the installed GitHub CLI as a Claude Code skill
{
  name = "gh";
  version = "1.0.0";
  description = "Expose the installed GitHub CLI as an installable skill";
  author = {
    name = "y0usaf";
  };

  skills = {
    gh = import ../../../../../../lib/ai/skills/gh.nix;
  };
}

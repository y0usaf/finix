{
  instructions = import ./instructions-text.nix;
  settings = import ./settings-defaults.nix;
  agents = import ./agents/default.nix;
  skills = import ../../../../lib/ai/skills;
}

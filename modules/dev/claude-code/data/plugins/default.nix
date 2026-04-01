# Plugin definitions for Claude Code marketplace
{
  agent-slack = import ./agent-slack/default.nix;
  audio-notify = import ./audio-notify/default.nix;
  codex-mcp = import ./codex-mcp/default.nix;
  collab-flow = import ./collab-flow/default.nix;
  gh = import ./gh/default.nix;
  instructify = import ./instructify/default.nix;
  linear-cli = import ./linear-cli/default.nix;
  teams-instruct = import ./teams-instruct/default.nix;
  todowrite-instruct = import ./todowrite-instruct/default.nix;
  tool-tracker = import ./tool-tracker/default.nix;
}

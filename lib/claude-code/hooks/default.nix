{
  utils = import ./utils/default.nix;
  notification = import ./notification/default.nix;
  stop = import ./stop/default.nix;
  subagent_stop = import ./subagent-stop/default.nix;
  skill_eval = import ./skill-eval/default.nix;
  # Tool enforcement hooks
  tool_tracker = import ./tool-tracker/default.nix;
  tool_validator = import ./tool-validator/default.nix;
  todowrite_reminder = import ./todowrite-reminder/default.nix;
  askuser_reminder = import ./askuser-reminder/default.nix;
  parallel_reminder = import ./parallel-reminder/default.nix;
}

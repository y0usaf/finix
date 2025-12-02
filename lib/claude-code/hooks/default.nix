{
  # Shared utilities
  utils = import ./utils/default.nix;

  # UserPromptSubmit hooks
  todowrite_reminder = import ./user-prompt-submit/todowrite-reminder.nix;
  askuser_reminder = import ./user-prompt-submit/askuser-reminder.nix;
  parallel_reminder = import ./user-prompt-submit/parallel-reminder.nix;
  codex_reminder = import ./user-prompt-submit/codex-reminder.nix;
  skill_eval = import ./user-prompt-submit/skill-eval.nix;

  # Stop hooks
  stop = import ./stop/completion-sound.nix;
  tool_validator = import ./stop/tool-validator.nix;

  # PreToolUse hooks
  tool_tracker = import ./pre-tool-use/tool-tracker.nix;
}

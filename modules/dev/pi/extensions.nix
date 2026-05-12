{
  config,
  lib,
  ...
}: let
  cfg = config.user.dev.pi;
in {
  config = lib.mkIf cfg.enable {
    user.dev.pi.extensionSettings = {
      "codex-fast" = false;
      "pi-compact" = {
        tools = {
          mode = "compact";
          gap = false;
        };
        user = {
          mode = "borderless";
          gap = true;
        };
      };
      "pi-pomodoro" = {
        workMinutes = 25;
        breakMinutes = 5;
        longBreakMinutes = 15;
        longBreakEvery = 4;
        notifyTransitions = true;
      };
      "pi-rlm" = {
        models = ["openai-codex/gpt-5.4-mini"];
        maxConcurrent = 4;
        maxDepth = 4;
      };
    };
  };
}

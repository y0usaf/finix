{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.dev.pi.enable {
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
    };
  };
}

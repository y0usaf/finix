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
    };
  };
}

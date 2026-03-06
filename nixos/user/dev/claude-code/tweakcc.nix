{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.dev.claude-code.enable {
    programs.tweakcc = {
      enable = true;
      settings = {
        misc = {
          hideStartupBanner = true;
          expandThinkingBlocks = false;
        };
        toolsets = [
          {
            name = "default";
            allowedTools = ["Bash" "WebFetch"];
          }
        ];
        defaultToolset = "default";
        planModeToolset = "default";
      };
    };
  };
}

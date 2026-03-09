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
        claudeMdAltNames = ["AGENTS.md"];
        toolsets = [
          {
            name = "undefined";
            allowedTools = ["Read" "Edit" "Write" "Glob" "Grep"];
          }
        ];
      };
    };
  };
}

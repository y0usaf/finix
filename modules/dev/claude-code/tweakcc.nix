{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.dev.claude-code.enable {
    programs.tweakcc = {
      enable = false; # temporarily disabled - tweakcc can't extract JS from current claude-code native binary
      settings = {
        misc = {
          hideStartupBanner = true;
          expandThinkingBlocks = false;
        };
        claudeMdAltNames = ["AGENTS.md"];
      };
    };
  };
}

{
  config,
  lib,
  ...
}: let
  skill = import ../../../../../lib/codex/skills/agent-slack.nix;
in {
  config = lib.mkIf (config.user.dev.codex.enable && config.user.dev.codex.skills.agent-slack.enable && config.user.dev.agent-slack.enable) {
    usr.files = {
      ".codex/skills/agent-slack/SKILL.md" = {
        text = skill.skill;
        clobber = true;
      };
      ".codex/skills/agent-slack/agents/openai.yaml" = {
        generator = lib.generators.toYAML {};
        value = {interface = skill.interface;};
        clobber = true;
      };
    };
  };
}

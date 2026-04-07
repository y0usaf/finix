{
  config,
  lib,
  ...
}: let
  skill = import ../../../../lib/ai/skills/agent-slack.nix;
  userDev = config.user.dev;
  codexCfg = userDev.codex;
in {
  config = lib.mkIf (codexCfg.enable && codexCfg.skills.agent-slack.enable && userDev.agent-slack.enable) {
    bayt.users."${config.user.name}".files = {
      ".codex/skills/agent-slack/SKILL.md" = {
        text = skill.skill;
      };
      ".codex/skills/agent-slack/agents/openai.yaml" = {
        generator = lib.generators.toYAML {};
        value = {inherit (skill) interface;};
      };
    };
  };
}

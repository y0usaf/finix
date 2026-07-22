{
  config,
  lib,
  ...
}: let
  skill = import ../../skills/agent-slack.nix {moduleMode = false;};
  userDev = config.user.dev;
  codexCfg = userDev.codex;
in {
  config = lib.mkIf (codexCfg.enable && (lib.attrByPath ["skills" "agent-slack" "enable"] true codexCfg) && userDev.work.agent-slack.enable) {
    manzil.users."${config.user.name}".files = {
      ".local/share/codex/skills/agent-slack/SKILL.md" = {
        text = skill.skill;
      };
      ".local/share/codex/skills/agent-slack/agents/openai.yaml" = {
        generator = lib.generators.toYAML {};
        value = {inherit (skill) interface;};
      };
    };
  };
}

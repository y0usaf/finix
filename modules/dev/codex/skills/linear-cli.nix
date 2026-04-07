{
  config,
  lib,
  ...
}: let
  skill = import ../../../../lib/ai/skills/linear-cli.nix;
  codexCfg = config.user.dev.codex;
in {
  config = lib.mkIf (codexCfg.enable && codexCfg.skills.linear-cli.enable) {
    bayt.users."${config.user.name}".files = {
      ".codex/skills/linear-cli/SKILL.md" = {
        text = skill.skill;
      };
      ".codex/skills/linear-cli/agents/openai.yaml" = {
        generator = lib.generators.toYAML {};
        value = {inherit (skill) interface;};
      };
    };
  };
}

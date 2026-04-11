{
  config,
  lib,
  ...
}: let
  skill = config.lib.ai.skills.gh;
  inherit (config) user;
  codexCfg = user.dev.codex;
  ghEnabled = lib.attrByPath ["tools" "gh" "enable"] false user;
in {
  config = lib.mkIf (codexCfg.enable && codexCfg.skills.gh.enable && ghEnabled) {
    bayt.users."${config.user.name}".files = {
      ".codex/skills/gh/SKILL.md" = {
        text = skill.skill;
      };
      ".codex/skills/gh/agents/openai.yaml" = {
        generator = lib.generators.toYAML {};
        value = {inherit (skill) interface;};
      };
    };
  };
}

{
  config,
  lib,
  ...
}: let
  skill = import ../../skills/gh.nix {moduleMode = false;};
  inherit (config) user;
  codexCfg = user.dev.codex;
  ghEnabled = lib.attrByPath ["tools" "gh" "enable"] false user;
  ghSkillEnabled = lib.attrByPath ["skills" "gh" "enable"] true codexCfg;
in {
  config = lib.mkIf (codexCfg.enable && ghSkillEnabled && ghEnabled) {
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

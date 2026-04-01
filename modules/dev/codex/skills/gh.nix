{
  config,
  lib,
  ...
}: let
  skill = import ../../../../lib/ai/skills/gh.nix;
  inherit (config) user;
  codexCfg = user.dev.codex;
  ghEnabled = lib.attrByPath ["tools" "gh" "enable"] false user;
in {
  config = lib.mkIf (codexCfg.enable && codexCfg.skills.gh.enable && ghEnabled) {
    bayt.users."${config.user.name}".files = {
      ".codex/skills/gh/SKILL.md" = {
        text = skill.skill;
        clobber = true;
      };
      ".codex/skills/gh/agents/openai.yaml" = {
        generator = lib.generators.toYAML {};
        value = {inherit (skill) interface;};
        clobber = true;
      };
    };
  };
}

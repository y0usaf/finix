{
  config,
  lib,
  ...
}: let
  skill = import ../../skills/gh.nix {moduleMode = false;};
  inherit (config) user;
  codexCfg = user.dev.codex;
in {
  config = lib.mkIf (codexCfg.enable && (lib.attrByPath ["skills" "gh" "enable"] true codexCfg) && (lib.attrByPath ["tools" "gh" "enable"] false user)) {
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

{
  config,
  lib,
  ...
}: let
  skill = import ../../skills/linear-cli.nix {moduleMode = false;};
  codexCfg = config.user.dev.codex;
  linearCliEnabled = lib.attrByPath ["skills" "linear-cli" "enable"] true codexCfg;
in {
  config = lib.mkIf (codexCfg.enable && linearCliEnabled) {
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

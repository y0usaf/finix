{
  config,
  lib,
  ...
}: let
  skill = import ../../skills/linear-cli.nix {moduleMode = false;};
  codexCfg = config.user.dev.codex;
in {
  config = lib.mkIf (codexCfg.enable && (lib.attrByPath ["skills" "linear-cli" "enable"] true codexCfg)) {
    manzil.users."${config.user.name}".files = {
      ".local/share/codex/skills/linear-cli/SKILL.md" = {
        text = skill.skill;
      };
      ".local/share/codex/skills/linear-cli/agents/openai.yaml" = {
        generator = lib.generators.toYAML {};
        value = {inherit (skill) interface;};
      };
    };
  };
}

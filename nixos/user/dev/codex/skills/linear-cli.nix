{
  config,
  lib,
  ...
}: let
  skill = import ../../../../../lib/codex/skills/linear-cli.nix;
in {
  config = lib.mkIf (config.user.dev.codex.enable && config.user.dev.codex.skills.linear-cli.enable) {
    usr.files = {
      ".codex/skills/linear-cli/SKILL.md" = {
        text = skill.skill;
        clobber = true;
      };
      ".codex/skills/linear-cli/agents/openai.yaml" = {
        generator = lib.generators.toYAML {};
        value = {inherit (skill) interface;};
        clobber = true;
      };
    };
  };
}

{
  config,
  lib,
  ...
}: let
  skill = import ../../../../../lib/codex/skills/gh.nix;
in {
  config = lib.mkIf (config.user.dev.codex.enable && config.user.dev.codex.skills.gh.enable && config.user.tools.gh.enable) {
    usr.files = {
      ".codex/skills/gh/SKILL.md" = {
        text = skill.skill;
        clobber = true;
      };
      ".codex/skills/gh/agents/openai.yaml" = {
        generator = lib.generators.toYAML {};
        value = {interface = skill.interface;};
        clobber = true;
      };
    };
  };
}

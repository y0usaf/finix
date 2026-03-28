{
  config,
  lib,
  ...
}: let
  skill = import ../data/skills/gh.nix;
  inherit (config) user;
  codexCfg = user.dev.codex;
in {
  config = lib.mkIf (codexCfg.enable && codexCfg.skills.gh.enable && user.tools.gh.enable) {
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

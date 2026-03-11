{
  config,
  lib,
  ...
}: let
  codexConfig = import ../../../../../lib/codex;
  skillIsAvailable = skillName: skill:
    config.user.dev.codex.skills.${skillName}.enable
    && (!(skill ? requiresAgentSlack) || !skill.requiresAgentSlack || config.user.dev.agent-slack.enable)
    && (!(skill ? requiresGh) || !skill.requiresGh || config.user.tools.gh.enable);
  enabledSkills = lib.filterAttrs skillIsAvailable codexConfig.skills;
  skillFiles = lib.foldl' (
    acc: skillName: let
      skill = enabledSkills.${skillName};
    in
      acc
      // {
        ".codex/skills/${skillName}/SKILL.md" = {
          text = skill.skill;
          clobber = true;
        };
      }
      // lib.optionalAttrs (skill ? interface) {
        ".codex/skills/${skillName}/agents/openai.yaml" = {
          generator = lib.generators.toYAML {};
          value = {
            interface = skill.interface;
          };
          clobber = true;
        };
      }
  ) {} (lib.attrNames enabledSkills);
in {
  config = lib.mkIf config.user.dev.codex.enable {
    usr.files = skillFiles;
  };
}

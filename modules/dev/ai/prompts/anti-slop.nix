{
  config,
  lib,
  ...
}: let
  inherit (config.lib.prompts) roots mkSkill;
in {
  config = lib.mkIf (roots != []) {
    manzil.users."${config.user.name}".files = lib.mkMerge (mkSkill "anti-slop" {
      "SKILL.md".text = config.user.dev.prompts.skillText.anti-slop;
    });
  };
}

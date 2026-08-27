{
  config,
  lib,
  ...
}: let
  inherit (import ./mapping.nix {inherit config lib;}) roots mkSkill;
in {
  config = lib.mkIf (roots != []) {
    manzil.users."${config.user.name}".files = lib.mkMerge (mkSkill "codebase-atlas" {
      "SKILL.md".text = import ./codebase-atlas/SKILL.nix;
    });
  };
}

{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.gaming.clair-obscur.mods;
  sources = import ./npins;

  expedition33Mods = pkgs.callPackage sources.Expedition-33-Mods {};

  availableMods = {
    enhanced-descriptions = {
      package = expedition33Mods.enhanced-descriptions;
      description = "Enhanced Descriptions with percentages";
    };
    gustave-weapon-skills = {
      package = expedition33Mods.gustave-weapon-skills;
      description = "Gustave Weapon Skills mod";
    };
    gustave-weapon-skill-rework = {
      package = expedition33Mods.gustave-weapon-skill-rework;
      description = "Gustave Weapon Skill Rework mod";
    };
  };
in {
  options.home.gaming.clair-obscur.mods = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Clair Obscur: Expedition 33 mod management";
    };

    enabledMods = lib.mkOption {
      type = lib.types.listOf (lib.types.enum (lib.attrNames availableMods));
      default = [];
      example = ["enhanced-descriptions" "gustave-weapon-skills" "gustave-weapon-skill-rework"];
      description = ''
        List of mod names to enable. Available mods:
        - enhanced-descriptions: Enhanced Descriptions with percentages
        - gustave-weapon-skills: Gustave Weapon Skills mod
        - gustave-weapon-skill-rework: Gustave Weapon Skill Rework mod
      '';
    };

    installAll = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install all available mods at once";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      (lib.optional cfg.installAll expedition33Mods.all-mods)
      ++ (map (modName: availableMods.${modName}.package) cfg.enabledMods);
  };
}

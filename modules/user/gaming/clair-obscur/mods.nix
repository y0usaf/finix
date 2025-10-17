{
  config,
  lib,
  flakeInputs,
  system,
  ...
}: let
  modsFlake = flakeInputs.expedition-33-mods.packages.${system};

  availableMods = {
    enhanced-descriptions = {
      package = modsFlake.enhanced-descriptions;
      description = "Enhanced Descriptions with percentages";
    };
    gustave-weapon-skills = {
      package = modsFlake.gustave-weapon-skills;
      description = "Gustave Weapon Skills mod";
    };
    gustave-weapon-skill-rework = {
      package = modsFlake.gustave-weapon-skill-rework;
      description = "Gustave Weapon Skill Rework mod";
    };
  };
in {
  options.user.gaming.clair-obscur.mods = {
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

  config = lib.mkIf config.user.gaming.clair-obscur.mods.enable {
    usr.files =
      (lib.optionalAttrs config.user.gaming.clair-obscur.mods.installAll {
        "install-all-clair-obscur-mods" = {
          clobber = true;
          source = "${modsFlake.all-mods}/bin/install-all-mods";
          executable = true;
        };
      })
      // (lib.listToAttrs (map (modName: {
          name = "install-clair-obscur-${modName}";
          value = {
            clobber = true;
            source = "${availableMods.${modName}.package}/bin/install-${modName}";
            executable = true;
          };
        })
        config.user.gaming.clair-obscur.mods.enabledMods));
  };
}

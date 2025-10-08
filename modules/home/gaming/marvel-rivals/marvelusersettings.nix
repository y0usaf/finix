{
  config,
  lib,
  ...
}: let
  settingsData = {
    MasterVolume = 70;
    SoundEffectVolume = 100;
    MusicVolume = 0;
    VoiceVolume = 100;
    UserControl = builtins.toJSON {
      "0" = builtins.toJSON {
        MouseHorizontalSensitivity = 5.0;
        MouseVerticalSensitivity = 5.0;
        CharControlInputMappings = {
          "6" = {PrimaryKey = {Key = "J";};};
          "24" = {PrimaryKey = {Key = "B";};};
          "36" = {PrimaryKey = {Key = "None";};};
          "46" = {PrimaryKey = {Key = "X";};};
          "47" = {PrimaryKey = {Key = "Z";};};
        };
        AbilityUserSettingList = [
          {
            SettingType = 1;
            Key = "WakandaUp";
            AbilityID = 200401;
            bIsGamepad = false;
            bIsDirty = false;
            Value = true;
          }
          {
            SettingType = 1;
            Key = "WakandaUp";
            AbilityID = 200401;
            bIsGamepad = true;
            bIsDirty = false;
            Value = false;
          }
        ];
        HpBarVisibleRule = 1;
      };
      "1035" = builtins.toJSON {
        AbilityUserSettingList = [
          {
            SettingType = 1;
            Key = "bIsHoldAbility";
            AbilityID = 103501;
            bIsGamepad = false;
            bIsDirty = false;
            Value = true;
          }
          {
            SettingType = 1;
            Key = "bIsHoldSprint";
            AbilityID = 103501;
            bIsGamepad = false;
            bIsDirty = false;
            Value = true;
          }
          {
            SettingType = 0;
            Key = "WallRunMode";
            AbilityID = 103501;
            bIsGamepad = false;
            bIsDirty = false;
            Value = "TowardUp";
          }
          {
            SettingType = 1;
            Key = "bIsHoldAbility";
            AbilityID = 103501;
            bIsGamepad = true;
            bIsDirty = false;
            Value = false;
          }
          {
            SettingType = 1;
            Key = "bIsHoldSprint";
            AbilityID = 103501;
            bIsGamepad = true;
            bIsDirty = false;
            Value = false;
          }
          {
            SettingType = 0;
            Key = "WallRunMode";
            AbilityID = 103501;
            bIsGamepad = true;
            bIsDirty = false;
            Value = "TowardUp";
          }
          {
            SettingType = 1;
            Key = "bIsHoldAbility";
            AbilityID = 103551;
            bIsGamepad = false;
            bIsDirty = false;
            Value = true;
          }
          {
            SettingType = 1;
            Key = "UseSimpleSwing";
            AbilityID = 103551;
            bIsGamepad = false;
            bIsDirty = false;
            Value = false;
          }
          {
            SettingType = 1;
            Key = "bIsHoldAbility";
            AbilityID = 103551;
            bIsGamepad = true;
            bIsDirty = false;
            Value = false;
          }
          {
            SettingType = 1;
            Key = "UseSimpleSwing";
            AbilityID = 103551;
            bIsGamepad = true;
            bIsDirty = false;
            Value = true;
          }
          {
            SettingType = 1;
            Key = "WakandaUp";
            AbilityID = 200401;
            bIsGamepad = false;
            bIsDirty = false;
            Value = true;
          }
          {
            SettingType = 1;
            Key = "WakandaUp";
            AbilityID = 200401;
            bIsGamepad = true;
            bIsDirty = false;
            Value = false;
          }
        ];
      };
      "1045" = builtins.toJSON {
        AbilityUserSettingList = [
          {
            SettingType = 1;
            Key = "bIsHoldAbility";
            AbilityID = 104541;
            bIsGamepad = false;
            bIsDirty = false;
            Value = false;
          }
          {
            SettingType = 1;
            Key = "bIsHoldAbility";
            AbilityID = 104541;
            bIsGamepad = true;
            bIsDirty = false;
            Value = false;
          }
          {
            SettingType = 1;
            Key = "bIsHoldAbility";
            AbilityID = 104542;
            bIsGamepad = false;
            bIsDirty = false;
            Value = true;
          }
          {
            SettingType = 1;
            Key = "bIsHoldAbility";
            AbilityID = 104542;
            bIsGamepad = true;
            bIsDirty = false;
            Value = false;
          }
          {
            SettingType = 1;
            Key = "WakandaUp";
            AbilityID = 200401;
            bIsGamepad = false;
            bIsDirty = false;
            Value = true;
          }
          {
            SettingType = 1;
            Key = "WakandaUp";
            AbilityID = 200401;
            bIsGamepad = true;
            bIsDirty = false;
            Value = false;
          }
        ];
      };
    };
  };
in {
  options.home.gaming.marvel-rivals.marvelusersettings = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Marvel Rivals MarvelUserSettings.ini configuration";
    };
  };
  config = lib.mkIf config.home.gaming.marvel-rivals.marvelusersettings.enable {
    usr.files =
      lib.genAttrs [
        ".local/share/Steam/steamapps/compatdata/2767030/pfx/drive_c/users/steamuser/AppData/Local/Marvel/Saved/Saved/Config/default/MarvelUserSetting.ini"
        ".local/share/Steam/steamapps/compatdata/2767030/pfx/drive_c/users/steamuser/AppData/Local/Marvel/Saved/Saved/Config/current/MarvelUserSetting.ini"
      ] (_: {
        clobber = true;
        generator = lib.generators.toJSON {};
        value = settingsData;
      });
  };
}

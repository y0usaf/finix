{
  config,
  lib,
  ...
}: {
  options.user.gaming.aethermancer = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Aethermancer configuration";
    };
  };
  config = lib.mkIf config.user.gaming.aethermancer.enable {
    manzil.users."${config.user.name}".files.".config/unity3d/moi rai games/Aethermancer/prefs".text = ''
      <unity_prefs version_major="1" version_minor="1">
      	<pref name="Screen_VSync_Enabled" type="int">0</pref>
      	<pref name="stg_user_setting_ui" type="int">1</pref>
      	<pref name="UnitySelectMonitor" type="int">0</pref>
      	<pref name="Screen_IsWindowed" type="int">1</pref>
      	<pref name="Screenmanager Resolution Width" type="int">2560</pref>
      	<pref name="Skip_Tutorial" type="int">0</pref>
      	<pref name="Accessibility_reduce_corruption" type="int">0</pref>
      	<pref name="Screen_Height" type="int">1440</pref>
      	<pref name="Accessibility_reduce_enemy_level" type="int">0</pref>
      	<pref name="Screen_Width" type="int">2560</pref>
      	<pref name="Screenmanager Resolution Height" type="int">1440</pref>
      	<pref name="Disable_Dynamic_Tutorial" type="int">0</pref>
      	<pref name="Screenmanager Fullscreen mode" type="int">3</pref>
      	<pref name="stg_user_setting_master" type="int">1</pref>
      	<pref name="Allow_Data_Tracking" type="int">1</pref>
      	<pref name="stg_user_setting_music" type="int">1</pref>
      	<pref name="Screen_Target_FPS" type="int">240</pref>
      	<pref name="SFX_Volume" type="float">0.8</pref>
      	<pref name="Preview_Enemy_Action_Targets" type="int">1</pref>
      	<pref name="Screenmanager Window Position Y" type="int">0</pref>
      	<pref name="Accessbility_disable_camera_shakes" type="int">0</pref>
      	<pref name="Using_Headphones" type="int">1</pref>
      	<pref name="Accessbility_disable_corruption" type="int">0</pref>
      	<pref name="Screen_Shake_Enabled" type="int">1</pref>
      	<pref name="stg_user_setting_sfx" type="int">1</pref>
      	<pref name="Screen_Target_FPS_Enabled" type="int">1</pref>
      	<pref name="Demo_Disclaimer_Displayed" type="int">1</pref>
      	<pref name="Accessibility_disable_reset_actions" type="int">0</pref>
      	<pref name="Screenmanager Window Position X" type="int">0</pref>
      	<pref name="combat_speed" type="int">0</pref>
      	<pref name="Screenmanager Resolution Use Native" type="int">0</pref>
      	<pref name="Music_Volume" type="float">0.7</pref>
      	<pref name="Data_Tracking_Disclaimer_Displayed" type="int">1</pref>
      	<pref name="Play_In_Background" type="int">0</pref>
      	<pref name="UI_Volume" type="float">0.8</pref>
      	<pref name="Master_Volume" type="float">1</pref>
      	<pref name="Current_Language" type="int">0</pref>
      	<pref name="Speedup_long_actions" type="int">1</pref>
      </unity_prefs>
    '';
  };
}

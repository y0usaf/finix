{
  config,
  lib,
  ...
}: let
  inherit (config) user;
in {
  options.user.gaming.solo-leveling-arise = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Solo Leveling: Arise configuration";
    };
  };

  config = lib.mkIf user.gaming.solo-leveling-arise.enable {
    patchix = {
      enable = true;
      users."${user.name}".patches."${lib.removePrefix "${user.homeDirectory}/" user.paths.steam.path}/steamapps/compatdata/2373990/pfx/user.reg" = {
        format = "reg";
        clobber = true;
        value = {
          "HKEY_CURRENT_USER\\Software\\Netmarble Corp\\sololvcsA\\options" = {
            "KEY_GRAPHIC_OPTION_ScreenResolutionX" = {
              type = "sz";
              value = "2543";
            };
            "KEY_GRAPHIC_OPTION_ScreenResolutionY" = {
              type = "sz";
              value = "1418";
            };
            "KEY_GRAPHIC_OPTION_FullScreenMode" = {
              type = "sz";
              value = "0";
            };
            "KEY_GRAPHIC_OPTION_VSync" = {
              type = "sz";
              value = "0";
            };
            "KEY_GRAPHIC_OPTION_FrameRate" = {
              type = "sz";
              value = "4";
            };
            "KEY_GRAPHIC_OPTION_RenderScale" = {
              type = "sz";
              value = "1";
            };
            "KEY_GRAPHIC_OPTION_TextureQuality" = {
              type = "sz";
              value = "4";
            };
            "KEY_GRAPHIC_OPTION_ShadowResolution" = {
              type = "sz";
              value = "4096";
            };
            "KEY_GRAPHIC_OPTION_ShadowDistance" = {
              type = "sz";
              value = "150";
            };
            "KEY_GRAPHIC_OPTION_SoftShadowQuality" = {
              type = "sz";
              value = "4";
            };
            "KEY_GRAPHIC_OPTION_AmbientOcclusion" = {
              type = "sz";
              value = "4";
            };
            "KEY_GRAPHIC_OPTION_Reflection" = {
              type = "sz";
              value = "4";
            };
            "KEY_GRAPHIC_OPTION_VolumetricFog" = {
              type = "sz";
              value = "3";
            };
            "KEY_GRAPHIC_OPTION_PostBloomQuality" = {
              type = "sz";
              value = "4";
            };
            "KEY_GRAPHIC_OPTION_PostBlurQuality" = {
              type = "sz";
              value = "3";
            };
            "KEY_GRAPHIC_OPTION_PostDOFQuality" = {
              type = "sz";
              value = "4";
            };
            "KEY_GRAPHIC_OPTION_PostEffectOn" = {
              type = "sz";
              value = "1";
            };
            "KEY_GRAPHIC_OPTION_MotionBlurOn" = {
              type = "sz";
              value = "0";
            };
            "KEY_GRAPHIC_OPTION_DepthOfField" = {
              type = "sz";
              value = "0";
            };
            "KEY_GRAPHIC_OPTION_AntiAliasingFilter" = {
              type = "sz";
              value = "0";
            };
            "KEY_GRAPHIC_OPTION_AntiAliasingSampleCount" = {
              type = "sz";
              value = "1";
            };
            "KEY_GRAPHIC_OPTION_CharQuality" = {
              type = "sz";
              value = "4";
            };
            "KEY_GRAPHIC_OPTION_GPUAnimation" = {
              type = "sz";
              value = "4";
            };
            "KEY_GRAPHIC_OPTION_ObjectPerformance" = {
              type = "sz";
              value = "4";
            };
            "KEY_GRAPHIC_OPTION_ParticleEffectQuality" = {
              type = "sz";
              value = "4";
            };
            "KEY_GRAPHIC_OPTION_TerrainQuality" = {
              type = "sz";
              value = "4";
            };
            "KEY_GRAPHIC_OPTION_ShaderQuality" = {
              type = "sz";
              value = "1";
            };
            "KEY_GRAPHIC_OPTION_LightQuality" = {
              type = "sz";
              value = "0";
            };
            "KEY_GRAPHIC_OPTION_VoxelShadowOn" = {
              type = "sz";
              value = "1";
            };
            "KEY_GRAPHIC_OPTION_AdaptivePerformance" = {
              type = "sz";
              value = "0";
            };
            "KEY_GRAPHIC_OPTION_Upscaling_FSR" = {
              type = "sz";
              value = "0";
            };
            "KEY_GRAPHIC_OPTION_Brightness" = {
              type = "sz";
              value = "0.5";
            };
            "KEY_GRAPHIC_OPTION_ObjectDensity" = {
              type = "sz";
              value = "100";
            };
            "KEY_GRAPHIC_OPTION_GrassDistance" = {
              type = "sz";
              value = "90";
            };
            "KEY_GRAPHIC_OPTION_DecalDistance" = {
              type = "sz";
              value = "60";
            };
            "KEY_GRAPHIC_OPTION_ScreenQuality" = {
              type = "sz";
              value = "3";
            };
          };
        };
      };
    };
  };
}

#===============================================================================
#                          🎮 Gaming Configuration 🎮
#===============================================================================
# 🎯 Steam settings
# 🎮 Gaming packages
# 🔧 Performance tweaks
#===============================================================================
{
  config,
  pkgs,
  lib,
  globals,
  ...
}: {
  config = lib.mkIf globals.enableGaming {
    # Gaming-related packages
    home.packages = with pkgs; [
      steam
      protonup-qt
      gamemode
      protontricks
      prismlauncher
    ];

    # Marvel Rivals game settings
    home.activation = {
      setupMarvelRivals = lib.hm.dag.entryAfter ["writeBoundary"] ''
                CONFIG_DIR="${globals.homeDirectory}/.local/share/Steam/steamapps/compatdata/2767030/pfx/drive_c/users/steamuser/AppData/Local/Marvel/Saved/Config/Windows"
                if [ -d "${globals.homeDirectory}/.local/share/Steam" ]; then
                  mkdir -p "$CONFIG_DIR"
                  cat > "$CONFIG_DIR/GameUserSettings.ini" << 'EOL'
        [Internationalization]
        Culture=en

        [ScalabilityGroups]
        sg.ViewDistanceQuality=1
        sg.ShadowQuality=0
        sg.PostProcessQuality=0
        sg.TextureQuality=0
        sg.EffectsQuality=0
        sg.FoliageQuality=0
        sg.ShadingQuality=0
        sg.ReflectionQuality=0
        sg.GlobalIlluminationQuality=0

        [/Script/Engine.GameUserSettings]
        bUseDesiredScreenHeight=False

        [/Script/Marvel.MarvelGameUserSettings]
        AntiAliasingSuperSamplingMode=4
        SuperSamplingQuality=4
        CASSharpness=0.000000
        ScreenPercentage=100.000000
        VoiceLanguage=
        bNvidiaReflex=False
        bXeLowLatency=False
        bDlssFrameGeneration=False
        bFSRFrameGeneration=False
        bXeFrameGeneration=False
        MonitorIndex=0
        bEnableConsole120Fps=False
        bUseVSync=False
        bUseDynamicResolution=False
        ResolutionSizeX=2560
        ResolutionSizeY=1440
        LastUserConfirmedResolutionSizeX=2560
        LastUserConfirmedResolutionSizeY=1440
        WindowPosX=1716
        WindowPosY=6
        FullscreenMode=2
        LastConfirmedFullscreenMode=2
        PreferredFullscreenMode=1
        Version=22
        AudioQualityLevel=0
        LastConfirmedAudioQualityLevel=0
        FrameRateLimit=0.000000
        DesiredScreenWidth=2560
        DesiredScreenHeight=1440
        LastUserConfirmedDesiredScreenWidth=2560
        LastUserConfirmedDesiredScreenHeight=1440
        LastRecommendedScreenWidth=-1.000000
        LastRecommendedScreenHeight=-1.000000
        LastCPUBenchmarkResult=-1.000000
        LastGPUBenchmarkResult=-1.000000
        LastGPUBenchmarkMultiplier=1.000000
        bUseHDRDisplayOutput=False
        HDRDisplayOutputNits=1000

        [CareerHighLight]
        HighLightVideoSavedPath=C:\users\steamuser\Videos\MarvelRivals\Highlights
        EOL
                fi
      '';
    };
  };
}

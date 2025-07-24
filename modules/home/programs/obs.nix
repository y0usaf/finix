{
  config,
  pkgs,
  lib,
  inputs,
  hostSystem,
  ...
}: let
  cfg = config.home.programs.obs;
  nvidiaCudaEnabled = hostSystem.hardware.nvidia.enable && (hostSystem.hardware.nvidia.cuda.enable or false);
  obsPackage =
    if nvidiaCudaEnabled
    then pkgs.obs-studio.override {cudaSupport = true;}
    else pkgs.obs-studio;
in {
  options.home.programs.obs = {
    enable = lib.mkEnableOption "OBS Studio";
  };
  config = lib.mkIf cfg.enable {
    users.users.y0usaf.maid.packages = with pkgs; [
      obsPackage
      obs-studio-plugins.obs-backgroundremoval
      obs-studio-plugins.obs-vkcapture
      obs-studio-plugins.obs-pipewire-audio-capture
      # inputs.obs-image-reaction.packages.${pkgs.system}.default # TODO: Fix for npins
      v4l-utils
    ];
  };
}

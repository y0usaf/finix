{
  config,
  lib,
  flakeInputs,
  ...
}: {
  config = lib.mkIf config.hardware.nvidia.enable {
    user.ui.tomoe.extraConfig = flakeInputs.mado.lib.tomoe;
  };
}

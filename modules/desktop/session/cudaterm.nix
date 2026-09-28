{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: {
  imports = [flakeInputs.cudaterm.finixModules.default];
  config.user.ui.cudaterm = {
    inherit (config.hardware.nvidia) enable;
    package = lib.mkIf config.hardware.nvidia.enable (flakeInputs.cudaterm.lib.mkFinixPackage {
      fontFile = "${flakeInputs.fonts.packages.${pkgs.stdenv.hostPlatform.system}.default}/share/fonts/truetype/DepartureMonoUltraCondensed-Regular.ttf";
      fontSize = config.user.appearance.termFontSize;
      lineHeight = lib.toInt (lib.removeSuffix "px" config.user.ui.foot.lineHeight);
    });
  };
}

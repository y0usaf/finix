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
      fontFile = "${flakeInputs.fonts.packages.${pkgs.stdenv.hostPlatform.system}.default}/share/fonts/truetype/Moono-Regular.ttf";
      fontSize = let
        pixels = config.user.appearance.termFontSize * 96.0 / 72.0;
        grid = 22 * lib.max 1 (builtins.floor (pixels / 22 + 0.5));
      in
        grid * 72.0 / 96.0;
      lineHeight = let
        match = builtins.match "([0-9]+)px" config.user.ui.foot.lineHeight;
      in
        if match == null
        then throw "cudaterm requires a pixel line height"
        else builtins.fromJSON (builtins.head match);
    });
  };
}

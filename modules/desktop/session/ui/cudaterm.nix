{
  config,
  lib,
  flakeInputs,
  ...
}: {
  imports = [flakeInputs.cudaterm.finixModules.default];
  config.user.ui.cudaterm = {
    inherit (config.hardware.nvidia) enable;
    package = lib.mkIf config.hardware.nvidia.enable (flakeInputs.cudaterm.lib.mkFinixPackage {
      fontFile = "${config.user.ui.fonts.mainFont}/share/fonts/truetype/DepartureMonoUltraCondensed-Regular.ttf";
      fontSize = config.user.appearance.termFontSize;
      lineHeight = let
        match = builtins.match "([0-9]+)px" config.user.ui.foot.lineHeight;
      in
        if match == null
        then throw "cudaterm requires a pixel line height"
        else builtins.fromJSON (builtins.head match);
    });
  };
}

{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.ui.niri.enable {
    usr.files.".config/niri/config.kdl".value.layout = {
      gaps = 10;
      center-focused-column = "never";
      default-column-display = "tabbed";
      default-column-width = {
        proportion = 0.5;
      };
      preset-column-widths = {
        _children = [
          {proportion = 0.33333;}
          {proportion = 0.5;}
          {proportion = 0.66667;}
        ];
      };

      # Border and tab-indicator colors are in wallust-generated include file
      border = {
        width = 1;
        # Colors set via wallust include below
      };

      focus-ring = {
        off = {};
      };

      tab-indicator = {
        width = 10;
        gap = -5;
        length = {
          _props = {
            "total-proportion" = 0.01;
          };
        };
        # Colors set via wallust include below
        position = "bottom";
      };
    };
  };
}

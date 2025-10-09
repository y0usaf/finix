{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.ui.niri.enable {
    user.ui.niri.settings.layout = {
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

      border = {
        width = 1;
        active-color = "ffffff";
        inactive-color = "#000000";
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
        active-color = "#ffffff";
        inactive-color = "aaaaaa";
        position = "bottom";
      };
    };
  };
}

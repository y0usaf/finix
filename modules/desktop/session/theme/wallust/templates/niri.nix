{
  config,
  lib,
  ...
}: let
  enabled = lib.attrByPath ["user" "ui" "niri" "enable"] false config;
in {
  config.user.appearance.wallust = {
    targets = lib.optionalAttrs enabled {
      "niri-borders" = {
        template = "niri-borders.kdl";
        target = "~/.cache/wallust/niri-borders.kdl";
      };
    };

    templates."niri-borders.kdl" = ''
      layout {
        border {
          on
          active-color "{{ cursor }}"
          inactive-color "{{ color8 }}"
        }
        tab-indicator {
          active-color "{{ cursor }}"
          inactive-color "{{ color8 }}"
        }
      }
    '';
  };
}

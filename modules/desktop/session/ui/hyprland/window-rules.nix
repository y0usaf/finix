{
  config,
  lib,
  ...
}: {
  config =
    lib.mkIf config.user.ui.hyprland.enable {
      manzil.users."${config.user.name}".files.".config/hypr/hyprland.conf" = {
        text =
          lib.mkAfter ''
            ${lib.concatMapStringsSep "
" (rule: "windowrule = ${rule}") [
                "match:class ^(launcher), float on, center on, size 300 600"
                "match:class ^(hyprland-share-picker), float on, center on"
                "match:class ^(firefox)$, match:title ^(Picture-in-Picture), float on"
                "match:class ^(firefox)$, match:title ^(Picture-in-Picture), opacity 0.75 override"
                "match:class ^(firefox)$, match:title ^(Picture-in-Picture), border_size 0"
                "match:class ^(firefox)$, match:title ^(Picture-in-Picture), size 30% 30%"
                "match:title ^(Lovely.*), workspace special:lovely"
                "match:float false, group set"
              ]}
            ${lib.concatMapStringsSep "
" (rule: "layerrule = ${rule}") [
                "match:namespace ^(notifications)$, blur 1"
              ]}
          '';
      };
    };
}

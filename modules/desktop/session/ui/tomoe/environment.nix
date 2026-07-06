{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.ui.tomoe.enable {
    # Mirror modules/desktop/session/services/xdg-portals.nix:67
    # (targets.niri-session): pull the portal services into the tomoe
    # session so ScreenCast/Screenshot are ready when the compositor starts.
    systemd.user.targets.tomoe-session = {
      wants = [
        "xdg-desktop-portal.service"
        "xdg-desktop-portal-gtk.service"
      ];
    };
  };
}

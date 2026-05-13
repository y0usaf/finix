{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.ui.hyprland.enable {
    manzil.users."${config.user.name}".files.".config/hypr/hyprland.conf".text = lib.mkAfter ''
      monitor = ,highres,auto,1
    '';
  };
}

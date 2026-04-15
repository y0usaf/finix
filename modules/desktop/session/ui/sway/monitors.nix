{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.ui.sway.enable {
    bayt.users."${config.user.name}".files.".config/sway/config".text = lib.mkAfter ''
      output DP-4 mode 5120x1440@239.761Hz pos 0 0
      output DP-2 mode 5120x1440@239.761Hz pos 0 0
      output HDMI-A-2 mode 1920x1080@60.000Hz pos 5120 0
    '';
  };
}

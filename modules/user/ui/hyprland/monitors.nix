{
  config,
  lib,
  genLib,
  ...
}: {
  config = lib.mkIf config.user.ui.hyprland.enable {
    usr.files.".config/hypr/hyprland.conf" = {
      clobber = true;
      text = lib.mkAfter (genLib.toHyprconf {
        attrs = {
          monitor = lib.mapAttrsToList (name: output: "${name},${output.mode},0x0,1") config.hardware.display.outputs;
        };
        importantPrefixes = ["$" "exec" "source"];
      });
    };
  };
}

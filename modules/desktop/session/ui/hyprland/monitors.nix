{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.ui.hyprland.enable {
    bayt.users."${config.user.name}".files.".config/hypr/hyprland.conf" = {
      text = lib.mkAfter (config.lib.generators.toHyprconf {
        attrs = {
          monitor = lib.mapAttrsToList (name: output: "${name},${output.mode},0x0,1") config.hardware.display.outputs;
        };
        importantPrefixes = ["$" "exec" "source"];
      });
    };
  };
}

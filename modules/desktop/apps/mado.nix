{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: {
  config = lib.mkIf config.hardware.nvidia.enable {
    environment.systemPackages = [flakeInputs.mado.packages.${pkgs.stdenv.hostPlatform.system}.mado-send];
    user.ui.tomoe.extraConfig =
      flakeInputs.mado.lib.tomoe
      + ''
        (setf +mado-bitrate+ 200)
        (setf +mado-keys+
              (append '(("D S C F" "Hold to move the panel you look at around you"
                         (nil "d" :move-up :stop-up) (nil "s" :move-left :stop-left)
                         (nil "c" :move-down :stop-down) (nil "f" :move-right :stop-right))
                        ("R" "Centre the headset panels" (nil "r" :home))
                        ("Shift R" "Make the main panel follow your head, or set it down" ((:shift) "r" :follow)))
                      (remove-if (lambda (group)
                                   (some (lambda (bind) (member (third bind) '(:move-up :home :follow)))
                                         (cddr group)))
                                 +mado-keys+)))
      '';
  };
}

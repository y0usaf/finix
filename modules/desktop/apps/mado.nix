{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: {
  config = lib.mkIf config.hardware.nvidia.enable {
    environment.systemPackages = let
      mado = flakeInputs.mado.packages.${pkgs.stdenv.hostPlatform.system};
    in [mado.mado-send mado.mado-timing];
    user.ui.tomoe.extraConfig =
      flakeInputs.mado.lib.tomoe
      + ''
        (setf +mado-bitrate+ 200)
        (setf +mado-keys+
              (append '(("D S C F" "Hold to move the panel you look at around you"
                         (nil "d" :move-up :stop-up) (nil "s" :move-left :stop-left)
                         (nil "c" :move-down :stop-down) (nil "f" :move-right :stop-right))
                        ("R" "Centre the headset panels" (nil "r" :home))
                        ("Shift R" "Make the main panel follow your head, or set it down" ((:shift) "r" :follow))
                        ("T" "Show or hide the room around you" (nil "t" :passthrough)))
                      (remove-if (lambda (group)
                                   (some (lambda (bind) (member (third bind) '(:move-up :home :follow :passthrough)))
                                         (cddr group)))
                                 +mado-keys+)))
      '';
  };
}

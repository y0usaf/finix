{
  config,
  lib,
  flakeInputs,
  inputPackages,
  ...
}: {
  config = lib.mkIf config.hardware.nvidia.enable {
    environment.systemPackages = let
      inherit (inputPackages) mado;
    in [mado.mado-send mado.mado-timing];
    user.ui.tomoe.extraConfig =
      flakeInputs.mado.lib.tomoe
      + ''
        (setf +mado-bitrate+ 200)
        (setf +mado-keys+
              (append '(("D S C F" "Hold to move the panel you look at around you"
                         (nil "d" "mado-move-up" "mado-stop-up") (nil "s" "mado-move-left" "mado-stop-left")
                         (nil "c" "mado-move-down" "mado-stop-down") (nil "f" "mado-move-right" "mado-stop-right"))
                        ("R" "Centre the headset panels" (nil "r" "mado-home"))
                        ("Shift R" "Make the main panel follow your head, or set it down" ((:shift) "r" "mado-follow"))
                        ("T" "Show or hide the room around you" (nil "t" "mado-passthrough")))
                      (remove-if (lambda (group)
                                   (some (lambda (bind) (member (third bind) '("mado-move-up" "mado-home" "mado-follow" "mado-passthrough") :test #'equal))
                                         (cddr group)))
                                 +mado-keys+)))
      '';
  };
}

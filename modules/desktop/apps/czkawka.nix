{
  config,
  pkgs,
  ...
}: let
  inherit (config.user.ui.gtk) scale;
in {
  environment.systemPackages = [
    (
      if scale == 1.0
      then pkgs.czkawka
      else
        pkgs.symlinkJoin {
          name = "czkawka-scaled";
          paths = [pkgs.czkawka];
          nativeBuildInputs = [pkgs.makeWrapper];
          postBuild = ''
            rm $out/bin/krokiet
            makeWrapper ${pkgs.czkawka}/bin/krokiet $out/bin/krokiet \
              --set-default SLINT_SCALE_FACTOR ${toString scale}
          '';
        }
    )
  ];
}

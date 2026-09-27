{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = [
    (pkgs.symlinkJoin {
      name = "czkawka-scaled";
      paths = [pkgs.czkawka];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        rm $out/bin/krokiet
        makeWrapper ${pkgs.czkawka}/bin/krokiet $out/bin/krokiet \
          --set-default SLINT_SCALE_FACTOR ${toString config.user.ui.gtk.scale}
      '';
    })
  ];
}

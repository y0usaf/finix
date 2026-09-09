{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.shell.ekko.menuVisual = lib.mkOption {
    type = lib.types.package;
    description = "Isolated graphical Ekko menu inspection launcher.";
    default = let
      ekko = config.user.shell.ekko.package;
    in
      pkgs.writeShellApplication {
        name = "finix-ekko-menu-visual";
        runtimeInputs = [pkgs.cage pkgs.kitty pkgs.grim (pkgs.python3.withPackages (p: [p.pillow]))];
        text = ''
          export LIBGL_DRIVERS_PATH="${pkgs.mesa}/lib/dri"
          export __EGL_VENDOR_LIBRARY_FILENAMES="${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json"
          export FONTCONFIG_FILE="${pkgs.makeFontsConf {fontDirectories = [pkgs.dejavu_fonts];}}"
          exec python ${./ekko-menu-visual.py} ${ekko}/bin/ekko ${./init.lisp} "''${1:-/tmp/finix-ekko-menu-visual}"
        '';
      };
  };
}

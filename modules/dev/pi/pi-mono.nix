{
  config,
  lib,
  ...
}: let
  piPkg = config.programs.pi.finalPackage;
in {
  config = lib.mkIf config.user.dev.pi.enable {
    programs.pi = {
      enable = true;
      full = true;
    };

    user.dev.pi = {
      readmePath = "${piPkg}/share/pi/README.md";
      docsPath = "${piPkg}/share/pi/docs";
      examplesPath = "${piPkg}/share/pi/examples";
    };
  };
}

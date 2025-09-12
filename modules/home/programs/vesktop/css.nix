{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
in {
  config = mkIf config.home.programs.vesktop.enable {
    usr.files.".config/vesktop/settings/quickCss.css" = {
      source = ./quickCss.css;
    };
  };
}

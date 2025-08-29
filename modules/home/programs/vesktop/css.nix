{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
in {
  config = mkIf config.home.programs.vesktop.enable {
    hjem.users.${config.user.name}.files.".config/vesktop/settings/quickCss.css" = {
      source = ./quickCss.css;
    };
  };
}

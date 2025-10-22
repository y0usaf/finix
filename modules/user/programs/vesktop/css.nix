{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.programs.vesktop.enable {
    usr.files.".config/vesktop/settings/quickCss.css" = {
      source = ./quickCss.css;
    };
  };
}

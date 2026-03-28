{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.ui.niri.enable {
    bayt.users."${config.user.name}".files =
      {
        ".config/zsh/.zprofile" = {
          text = lib.mkAfter ''
            #niri
          '';
        };
      }
      // lib.optionalAttrs config.user.shell.nushell.enable {
        ".config/nushell/login.nu" = {
          text = lib.mkAfter ''
            #niri
          '';
          clobber = true;
        };
      };
  };
}

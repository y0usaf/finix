{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.ui.niri.enable {
    usr.files.".config/zsh/.zprofile" = {
      text = lib.mkAfter ''
        niri-session
      '';
    };
  };
}

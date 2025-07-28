{
  config,
  lib,
  pkgs,
  ...
}: let
  username = config.user.name;
in {
  config = lib.mkIf config.home.programs.firefox.enable {
    hjem.users.${username} = {
      packages = with pkgs; [
        firefox
      ];
      files = {
        ".profile" = {
          text = lib.mkAfter ''
            export MOZ_ENABLE_WAYLAND=1
            export MOZ_USE_XINPUT2=1
          '';
          clobber = true;
        };
      };
    };
  };
}

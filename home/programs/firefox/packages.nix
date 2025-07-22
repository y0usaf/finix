{
  config,
  lib,
  pkgs,
  ...
}: let
  username = "y0usaf";
in {
  config = lib.mkIf config.home.programs.firefox.enable {
    users.users.${username}.maid = {
      packages = with pkgs; [
        firefox
      ];
      file.home = {
        ".profile".text = lib.mkAfter ''
          export MOZ_ENABLE_WAYLAND=1
          export MOZ_USE_XINPUT2=1
        '';
      };
    };
  };
}

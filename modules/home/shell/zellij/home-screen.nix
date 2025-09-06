{
  config,
  lib,
  ...
}: let
  cfg = config.home.shell.zellij;
in {
  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name}.files = {
      ".config/zellij/layouts/home-screen.kdl" = {
        clobber = true;
        source = ./home-screen.kdl;
      };
    };
  };
}

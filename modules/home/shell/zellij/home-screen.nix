{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.home.shell.zellij.enable {
    usr.files = {
      ".config/zellij/layouts/home-screen.kdl" = {
        clobber = true;
        source = ./home-screen.kdl;
      };
    };
  };
}

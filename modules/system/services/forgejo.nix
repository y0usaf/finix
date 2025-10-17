{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.services.forgejo.enable {
    services.forgejo = {
      database.type = lib.mkDefault "postgres";
      lfs.enable = lib.mkDefault true;
      settings = {
        server = {
          HTTP_PORT = lib.mkDefault 3000;
          DOMAIN = lib.mkDefault "localhost";
          ROOT_URL = lib.mkDefault "http://localhost:3000/";
          SSH_DOMAIN = lib.mkDefault "y0usaf-server";
          START_SSH_SERVER = true;
          SSH_PORT = 2222;
        };
      };
    };

    services.postgresql.enable = lib.mkDefault true;
  };
}

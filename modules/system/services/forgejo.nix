{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.services.forgejo.enable {
    services.forgejo = {
      database.type = lib.mkDefault "postgres";
      lfs.enable = lib.mkDefault true;
      settings = lib.mkDefault {
        server = {
          HTTP_PORT = 3000;
          DOMAIN = "localhost";
          ROOT_URL = "http://localhost:3000/";
        };
      };
    };

    services.postgresql.enable = lib.mkDefault true;
  };
}

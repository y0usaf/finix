{
  lib,
  hostConfig,
  ...
}: let
  cfg = hostConfig.services.forgejo or {};
in {
  config = lib.mkIf (cfg.enable or false) {
    services.forgejo = {
      enable = true;
      database.type = "postgres";
      lfs.enable = true;
      settings = lib.mkMerge [
        {
          server = {
            HTTP_PORT = 3000;
            DOMAIN = "localhost";
            ROOT_URL = "http://localhost:3000/";
          };
        }
        (cfg.settings or {})
      ];
    };

    services.postgresql.enable = true;
  };
}

{
  lib,
  hostConfig,
  ...
}: {
  config = lib.mkIf (lib.attrByPath ["services" "forgejo" "enable"] false hostConfig) {
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
        (lib.attrByPath ["services" "forgejo" "settings"] {} hostConfig)
      ];
    };

    services.postgresql.enable = true;
  };
}

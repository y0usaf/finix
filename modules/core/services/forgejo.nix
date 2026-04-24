{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.services.forgejo.enable {
    users = {
      # Pin forgejo uid/gid so persisted /var/lib/forgejo ownership survives
      # service-user reordering across rebuilds.
      users.forgejo.uid = lib.mkDefault 993;
      groups.forgejo.gid = lib.mkDefault 989;
    };

    services = {
      forgejo = {
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
          repository.ENABLE_PUSH_CREATE_USER = true;
        };
      };
      postgresql.enable = lib.mkDefault true;
    };
  };
}

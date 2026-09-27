{pkgs, ...}: {
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    authentication = ''
      local all all peer
    '';
  };

  users = {
    users.forgejo = {
      isSystemUser = true;
      uid = 993;
      group = "forgejo";
      home = "/var/lib/forgejo";
    };
    groups.forgejo.gid = 989;
  };

  finit.services.forgejo = {
    description = "forgejo git hosting";
    user = "forgejo";
    group = "forgejo";
    command = "${pkgs.writeShellScript "forgejo-start" ''
      for _ in $(seq 1 60); do
        ${pkgs.postgresql_16}/bin/pg_isready -q -h /run/postgresql && break
        sleep 1
      done
      ${pkgs.postgresql_16}/bin/pg_isready -q -h /run/postgresql || exit 1
      exec ${pkgs.forgejo-lts}/bin/forgejo web
    ''}";
    path = [
      pkgs.forgejo-lts
      pkgs.git
      pkgs.gnupg
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnugrep
      pkgs.gnused
      pkgs.bash
    ];
    environment = {
      HOME = "/var/lib/forgejo";
      FORGEJO_WORK_DIR = "/var/lib/forgejo";
      FORGEJO_CUSTOM = "/var/lib/forgejo/custom";
      FORGEJO__SECURITY__SECRET_KEY__FILE = "/var/lib/forgejo/custom/conf/secret_key";
      FORGEJO__SECURITY__INTERNAL_TOKEN__FILE = "/var/lib/forgejo/custom/conf/internal_token";
      FORGEJO__SERVER__LFS_JWT_SECRET__FILE = "/var/lib/forgejo/custom/conf/lfs_jwt_secret";
      FORGEJO__OAUTH2__JWT_SECRET__FILE = "/var/lib/forgejo/custom/conf/oauth2_jwt_secret";
    };
    conditions = [
      "net/lo/up"
      "service/syslogd/ready"
    ];
    log = true;
  };

  environment.systemPackages = [pkgs.postgresql_16];
}

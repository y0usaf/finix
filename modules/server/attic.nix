{
  lib,
  pkgs,
  ...
}: {
  fileSystems."/var/lib/atticd" = {
    device = "/persist/var/lib/atticd";
    fsType = "btrfs";
    options = ["bind"];
    neededForBoot = true;
  };

  finit.tasks.atticd-keygen = {
    description = "generate atticd RS256 signing keypair if absent";
    command = pkgs.writeShellScript "atticd-keygen" ''
      export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.openssl]}
      install -d -m 0700 /var/lib/atticd
      if [ ! -s /var/lib/atticd/signing.pem ]; then
        openssl genrsa -out /var/lib/atticd/signing.pem.tmp 4096
        chmod 0400 /var/lib/atticd/signing.pem.tmp
        mv /var/lib/atticd/signing.pem.tmp /var/lib/atticd/signing.pem
        echo "atticd-keygen: new signing keypair"
      fi
      {
        printf 'ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64='
        base64 -w0 /var/lib/atticd/signing.pem
        printf '\n'
      } > /var/lib/atticd/token.env.tmp
      chmod 0400 /var/lib/atticd/token.env.tmp
      mv /var/lib/atticd/token.env.tmp /var/lib/atticd/token.env
      install -d -m 0755 /var/lib/atticd/storage
    '';
    log = true;
  };

  finit.services.atticd = {
    description = "attic binary cache server";
    command = pkgs.writeShellScript "atticd-run" ''
      set -a
      . /var/lib/atticd/token.env
      set +a
      exec ${pkgs.attic-server}/bin/atticd -f ${pkgs.writeText "atticd.toml" ''
        listen = "[::]:8787"
        require-proof-of-possession = false

        [database]
        url = "sqlite:///var/lib/atticd/atticd.db?mode=rwc"

        [storage]
        type = "local"
        path = "/var/lib/atticd/storage"

        [chunking]
        nar-size-threshold = 1048576
        min-size = 262144
        avg-size = 1048576
        max-size = 4194304
      ''}
    '';
    path = [pkgs.coreutils];
    environment = {
      RUST_LOG = "attic=info";
    };
    conditions = [
      "net/lo/up"
      "task/atticd-keygen/success"
    ];
    log = true;
  };
}

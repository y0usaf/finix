# atticd: binary cache server on the finix server.
#
# Why: CUDA-onnxruntime-class builds (hours, full load) should happen once
# and be substitutable by every machine on the tailnet. atticd serves a
# push-based cache on :8787 (tailscale-only via the firewall); the desktop
# pushes after heavy builds and all hosts pull as a substituter.
#
# Auth model (attic's): one RS256 keypair signs JWTs. The PEM lives
# root-only at /var/lib/atticd/signing.pem (impermanence-persisted). Admin
# tokens are minted on the server with atticd-atticadm.
{
  config,
  lib,
  pkgs,
  ...
}: let
  attic = pkgs.attic-server;

  configFile = pkgs.writeText "atticd.toml" ''
    listen = "[::]:8787"
    require-proof-of-possession = false

    [database]
    # embedded sqlite in the state dir; single-box scale
    url = "sqlite:///var/lib/atticd/atticd.db"

    [storage]
    type = "local"
    path = "/var/lib/atticd/storage"

    [signing]
    # root-only; written by the activation task below
    keypair = "/var/lib/atticd/signing.pem"

    [chunking]
    nar-size-threshold = 65536
    min-size = 4096
    avg-size = 16384
    max-size = 65536
  '';
in {
  # State out of /persist (impermanence), same pattern as forgejo.
  fileSystems."/var/lib/atticd" = {
    device = "/persist/var/lib/atticd";
    fsType = "none";
    options = ["bind"];
    depends = ["/persist"];
  };

  # signing.pem: generate once, root-only. finit task runs before the
  # service (same boot ordering as other one-shot tasks here).
  finit.tasks.atticd-keygen = {
    description = "generate atticd RS256 signing keypair if absent";
    command = pkgs.writeShellScript "atticd-keygen" ''
      export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.attic-server]}
      install -d -m 0700 /var/lib/atticd
      if [ ! -s /var/lib/atticd/signing.pem ]; then
        atticd generate-signing-key > /var/lib/atticd/signing.pem.tmp
        chmod 0400 /var/lib/atticd/signing.pem.tmp
        mv /var/lib/atticd/signing.pem.tmp /var/lib/atticd/signing.pem
        echo "atticd-keygen: new signing keypair"
      fi
      install -d -m 0755 /var/lib/atticd/storage
    '';
    log = true;
  };

  finit.services.atticd = {
    description = "attic binary cache server";
    command = "${attic}/bin/atticd -f ${configFile}";
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

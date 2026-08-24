# atticd: binary cache server on the finix server.
#
# Why: CUDA-onnxruntime-class builds (hours, full load) should happen once
# and be substitutable by every machine on the tailnet. atticd serves a
# push-based cache on :8787 (tailscale-only via the firewall); the desktop
# pushes after heavy builds and all hosts pull as a substituter.
#
# Auth model (attic's): one RS256 keypair signs JWTs. The PKCS1 PEM lives
# root-only at /var/lib/atticd/signing.pem (impermanence-persisted) and is
# handed to atticd as base64 via ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64,
# sourced from a root-only runtime env file (never the world-readable
# /nix/store config). Admin tokens are minted on the server with atticadm.
{
  lib,
  pkgs,
  ...
}:
# JWT signing secret comes from the env file below, not the TOML: attic
# reads [jwt.signing] token-rs256-secret-base64, falling back to
# ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64 when the TOML omits it.
{
  # State out of /persist (impermanence), same pattern as forgejo.
  # Same shape as services.nix's persistBind: finix ignores fsType "none" +
  # depends (NixOS idioms); binds must declare btrfs + neededForBoot to be
  # mounted from initrd. fsType is ignored for binds but must be listed in
  # supportedFilesystems, hence btrfs.
  fileSystems."/var/lib/atticd" = {
    device = "/persist/var/lib/atticd";
    fsType = "btrfs";
    options = ["bind"];
    neededForBoot = true;
  };

  # signing.pem: generate once, root-only. finit task runs before the
  # service (same boot ordering as other one-shot tasks here).
  finit.tasks.atticd-keygen = {
    description = "generate atticd RS256 signing keypair if absent";
    command = pkgs.writeShellScript "atticd-keygen" ''
      export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.openssl]}
      install -d -m 0700 /var/lib/atticd
      if [ ! -s /var/lib/atticd/signing.pem ]; then
        # attic ships no keygen subcommand; RS256 keys are plain PKCS1 PEM.
        openssl genrsa -out /var/lib/atticd/signing.pem.tmp 4096
        chmod 0400 /var/lib/atticd/signing.pem.tmp
        mv /var/lib/atticd/signing.pem.tmp /var/lib/atticd/signing.pem
        echo "atticd-keygen: new signing keypair"
      fi
      # Runtime env file the service sources: base64 PEM, root-only.
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
    # Source the root-only runtime env (JWT secret) before exec; finit's env:
    # stanza only points at world-readable /nix/store files.
    command = pkgs.writeShellScript "atticd-run" ''
      set -a
      . /var/lib/atticd/token.env
      set +a
      exec ${pkgs.attic-server}/bin/atticd -f ${pkgs.writeText "atticd.toml" ''
        listen = "[::]:8787"
        require-proof-of-possession = false

        [database]
        # embedded sqlite in the state dir; single-box scale. sqlx needs
        # ?mode=rwc to create the file (NixOS module does the same).
        url = "sqlite:///var/lib/atticd/atticd.db?mode=rwc"

        [storage]
        type = "local"
        path = "/var/lib/atticd/storage"

        [chunking]
        # big chunks: 16KiB-default dedup crawls on CUDA-class NARs (75k chunks
        # for 1.2GB = sqlite-bound, ~400KiB/s). 1MiB avg uploaded at 26-40MiB/s.
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

# Rootless podman with a docker shim. Finix's compat shim drops the NixOS
# virtualisation.* namespace, so the wiring that module used to do is
# declared directly:
#   - docker shim: Grok Bot's local Docker VM shells out to the docker
#     binary; podman's CLI is docker-compatible (this reverses the earlier
#     "docker CLIs stay excluded" stance from materialized-packages.nix on
#     purpose).
#   - newuidmap/newgidmap setuid wrappers: rootless UID mapping needs them.
#   - /etc/subuid + /etc/subgid: the subordinate ranges rootless containers
#     map into (what autoSubUidGidRange would have allocated).
#   - pasta, netavark, aardvark-dns: rootless networking helpers podman looks
#     up on PATH; fuse-overlayfs as the rootless overlay fallback.
{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "docker" ''
      exec ${pkgs.podman}/bin/podman "$@"
    '')
    pkgs.passt
    pkgs.netavark
    pkgs.aardvark-dns
    pkgs.fuse-overlayfs
  ];

  environment.etc."containers/policy.json".text = builtins.toJSON {
    default = [
      {
        type = "insecureAcceptAnything";
      }
    ];
  };

  security.wrappers = {
    newuidmap = {
      setuid = true;
      owner = "root";
      group = "root";
      source = "${pkgs.shadow}/bin/newuidmap";
    };
    newgidmap = {
      setuid = true;
      owner = "root";
      group = "root";
      source = "${pkgs.shadow}/bin/newgidmap";
    };
  };

  environment.etc."subuid".text = "${config.user.name}:100000:65536\n";
  environment.etc."subgid".text = "${config.user.name}:100000:65536\n";
}

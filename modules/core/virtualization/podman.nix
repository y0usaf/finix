{
  config,
  lib,
  pkgs,
  ...
}: {
  environment = {
    systemPackages = [
      (pkgs.writeShellScriptBin "docker" ''
        exec ${pkgs.podman}/bin/podman "$@"
      '')
      pkgs.passt
      pkgs.netavark
      pkgs.aardvark-dns
      pkgs.fuse-overlayfs
    ];

    etc."containers/policy.json".text = builtins.toJSON {
      default = [
        {
          type = "insecureAcceptAnything";
        }
      ];
    };

    etc."subuid" = {
      text = "${config.user.name}:100000:65536\n";
      mode = "0644";
    };
    etc."subgid" = {
      text = "${config.user.name}:100000:65536\n";
      mode = "0644";
    };
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
}

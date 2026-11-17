{ config, lib, pkgs, ... }:
let
  inherit (config.user) name homeDirectory;
  repo = "/home/y0usaf/dev/maintaining/tomoe";
  runtime = "/run/user/1001/agent";
  # The canonical copy of this script is Tomoe's land.sh; it runs from here until
  # the package ships bin/tomoe-land, so the queue survives restarts either way.
  queue = pkgs.writeShellScriptBin "tomoe-land" (builtins.readFile ./tomoe-land.sh);
in
{
  config = {
    environment.systemPackages = [ queue ];
    finit.services.tomoe-land = {
      description = "Tomoe landing queue: smoke gate, then push main";
      user = name;
      group = "users";
      command = "${pkgs.writeShellScript "tomoe-land-start" ''
        set -eu
        export PATH=${
          lib.concatStringsSep ":" [
            "${queue}/bin"
            "${pkgs.coreutils}/bin"
            "${pkgs.git}/bin"
            "${pkgs.util-linux}/bin"
            "/run/wrappers/bin"
            "/run/current-system/sw/bin"
            "/nix/var/nix/profiles/default/bin"
            "${homeDirectory}/.nix-profile/bin"
          ]
        }:$PATH
        for _ in $(seq 1 120); do
          [ -d ${runtime} ] && [ -d ${repo} ] && break
          sleep 1
        done
        mkdir -p ${runtime}
        cd ${repo}
        exec tomoe-land daemon
      ''}";
      environment = {
        HOME = homeDirectory;
        TOMOE_LAND_ROOT = "${runtime}/tomoe-land";
        TOMOE_LOCK = "${runtime}/tomoe-vm.lock";
        TOMOE_PENDING = "${runtime}/tomoe-vm.pending";
        TOMOE_AGENT = "tomoe-land";
        SSH_AUTH_SOCK = "/run/user/1001/ssh-agent";
      };
      log = true;
    };
  };
}

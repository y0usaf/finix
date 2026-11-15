{ config, lib, pkgs, inputPackages, ... }:
let
  inherit (config.user) name homeDirectory;
  repo = "/home/y0usaf/dev/maintaining/tomoe";
  runtime = "/run/user/1001/agent";
in
{
  config = {
    finit.services.tomoe-land = {
      description = "Tomoe landing queue: smoke gate, then push main";
      user = name;
      group = "users";
      command = "${pkgs.writeShellScript "tomoe-land-start" ''
        set -eu
        export PATH=${
          lib.concatStringsSep ":" [
            "${pkgs.coreutils}/bin"
            "${pkgs.git}/bin"
            "${pkgs.util-linux}/bin"
            "/run/current-system/sw/bin"
            "/nix/var/nix/profiles/default/bin"
            "${homeDirectory}/.nix-profile/bin"
          ]
        }:$PATH
        # the queue writes under the user's runtime dir and needs the checkout
        for _ in $(seq 1 120); do
          [ -d ${runtime} ] && [ -d ${repo} ] && break
          sleep 1
        done
        mkdir -p ${runtime}
        cd ${repo}
        exec ${inputPackages.tomoe.default}/bin/tomoe-land daemon
      ''}";
      environment = {
        HOME = homeDirectory;
        TOMOE_LAND_ROOT = "${runtime}/tomoe-land";
        TOMOE_LOCK = "${runtime}/tomoe-vm.lock";
        TOMOE_PENDING = "${runtime}/tomoe-vm.pending";
        TOMOE_AGENT = "tomoe-land";
        LAND_BASE = "origin/main";
        LAND_SYSTEM = "x86_64-linux";
      };
      log = true;
    };
  };
}

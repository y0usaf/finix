{
  inputs,
  pkgs,
  lib,
}: let
  inputPackages = lib.mapAttrs (_: input: input.packages.${pkgs.stdenv.hostPlatform.system} or {}) inputs;
  inherit (inputs) finix;
  qemuModule = import "${finix}/modules/virtualisation/qemu.nix";
  system = finix.lib.finixSystem {
    inherit (pkgs) lib;
    specialArgs = {
      flakeInputs = inputs;
      inherit inputPackages;
    };
    modules = [
      {
        nixpkgs.pkgs = pkgs;
      }
      finix.nixosModules.bash
      finix.nixosModules.getty
      finix.nixosModules.sysklogd
      qemuModule
      ./bootvine.nix
      ({config, ...}: {
        finix.bootScreen.enable = true;
        services.sysklogd.enable = true;

        fileSystems."/" = {
          device = "tmpfs";
          fsType = "tmpfs";
          neededForBoot = true;
          options = ["mode=0755"];
        };

        boot.kernelParams = [
          "console=ttyS0"
          "console=tty0"
          "loglevel=4"
        ];

        boot.initrd.availableKernelModules = ["9p" "9pnet_virtio"];

        users.users.root.password = "";
        environment.systemPackages = [
          pkgs.bash
          pkgs.coreutils
          pkgs.util-linux
          pkgs.gnugrep
          pkgs.procps
        ];

        services.getty = {
          enable = true;
          ttys = ["tty1"];
        };

        finit = {
          ttys.serial = {
            device = "/dev/ttyS0";
            runlevel = "S0123456";
            nologin = true;
            nowait = true;
          };

          tasks = {
            slowpoke = {
              description = "deliberately slow service";
              runlevel = "S";
              script = "sleep 8";
            };

            broken = {
              description = "deliberately failing service";
              runlevel = "S2";
              log = true;
              script = "echo 'cannot frobnicate the widget'; exit 3";
            };

            delayed = {
              description = "deliberately slow runlevel 2 task";
              runlevel = "2";
              script = "touch /run/delayed-start; sleep 45; touch /run/delayed-done";
            };
          };

          services.slowstop = {
            description = "deliberately slow to stop";
            runlevel = "234";
            stop-timeout = 8;
            restart = 0;
            script = ''
              trap 'sleep 4; exit 0' TERM
              while :; do
                sleep 0.2
              done
            '';
          };
        };

        virtualisation = {
          memorySize = 2048;
          cores = 2;
          qemu.extraArgs = [
            "-display"
            "none"
            "-vga"
            "std"
            "-no-reboot"
          ];
        };
      })
    ];
  };
in
  pkgs.stdenvNoCC.mkDerivation {
    name = "boot-screen-vm";
    nativeBuildInputs = [pkgs.python3];
    buildCommand = ''
      mkdir -p $out
      echo '${builtins.toJSON system.config.virtualisation.qemu.argv}' > $TMPDIR/argv.json
      python3 ${./bootvine-vm.py} --argv $TMPDIR/argv.json --out $out --work $TMPDIR
    '';
    requiredSystemFeatures = [];
  }

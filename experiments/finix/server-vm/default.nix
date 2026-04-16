{
  inputs,
  system,
}: let
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfreePredicate = pkg: builtins.elem (pkg.pname or (builtins.parseDrvName (pkg.name or "")).name) ["n8n"];
  };
  inherit (pkgs) lib;

  commonModule = import ./common.nix inputs;
  impermanenceModule = import ./impermanence.nix;
  finixModules = import "${inputs.finix.outPath}/modules";
  allFinixModules = builtins.attrValues (builtins.removeAttrs finixModules ["default"]);

  manualBaseModule = {
    nixpkgs.pkgs = pkgs;
    boot.kernelParams = ["console=ttyS0,115200n8"];
    fileSystems."/" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = ["mode=755" "size=3072M"];
    };
    virtualisation.cores = 4;
    virtualisation.memorySize = 4096;
    virtualisation.qemu.package = pkgs.qemu;
    virtualisation.qemu.nics.usernet.args = [
      "user"
      "model=virtio-net-pci"
      "hostfwd=tcp::22222-:22"
      "hostfwd=tcp::22223-:2222"
      "hostfwd=tcp::23000-:3000"
      "hostfwd=tcp::25678-:5678"
      "hostfwd=tcp::28384-:8384"
      "hostfwd=tcp::24200-:4200"
    ];
    virtualisation.qemu.extraArgs = ["-nographic"];
  };

  manualSystem = inputs.finix.lib.finixSystem {
    inherit lib;
    modules =
      allFinixModules
      ++ [
        "${inputs.finix.outPath}/modules/virtualisation/qemu.nix"
        (manualBaseModule
          // {
            virtualisation.qemu.sharedDirectories.nixos = {
              source = "/home/y0usaf/nixos";
              target = "/home/y0usaf/nixos";
              securityModel = "none";
            };
          })
        commonModule
      ];
  };

  impermanentManualSystem = inputs.finix.lib.finixSystem {
    inherit lib;
    modules =
      allFinixModules
      ++ [
        "${inputs.finix.outPath}/modules/virtualisation/qemu.nix"
        (manualBaseModule
          // {
            virtualisation.qemu.sharedDirectories.nixos = {
              source = "/home/y0usaf/nixos";
              target = "/mnt/nixos";
              securityModel = "none";
            };
          })
        commonModule
        impermanenceModule
      ];
  };

  testDriver = (import "${inputs.finix.outPath}/tests/lib/driver.nix" {inherit pkgs;}).overrideAttrs (_: {
    doInstallCheck = false;
    installCheckPhase = ":";
  });

  mkVm = nodes: name: nodeConfig:
    lib.evalModules {
      specialArgs = {
        inherit nodes;
      };
      modules =
        [
          "${inputs.finix.outPath}/tests/lib/testing.nix"
          "${inputs.finix.outPath}/modules/virtualisation/qemu.nix"
          nodeConfig
          {
            nixpkgs.pkgs = pkgs;
            boot.kernelParams = ["console=ttyS0,115200n8"];
            fileSystems."/" = {
              device = "tmpfs";
              fsType = "tmpfs";
              options = ["mode=755"];
            };
            networking.hostName = name;
            testing.enable = true;
            virtualisation.qemu.package = pkgs.qemu_test;
          }
        ]
        ++ builtins.attrValues finixModules;
    };

  mkVmScript = {
    name,
    config,
    persistentDiskSize ? null,
  }: let
    qemuArgs = config.virtualisation.qemu.argv;
    vlan = config.testing.network.vlan;
    mac = config.testing.network.mac;
    persistentDisk = "$TMPDIR/${name}-persist.qcow2";
  in
    pkgs.writeShellScript "run-${name}-vm" ''
      set -e

      if [ -n "$TMPDIR" ]; then
        mkdir -p "$TMPDIR"
        cd "$TMPDIR"
      fi

      if [ -n "$SHARED_DIR" ]; then
        mkdir -p "$SHARED_DIR"
      fi

      ${lib.optionalString (persistentDiskSize != null) ''
        persist_disk="${persistentDisk}"
        if ! [ -e "$persist_disk" ]; then
          ${config.virtualisation.qemu.package}/bin/qemu-img create -f qcow2 "$persist_disk" ${persistentDiskSize} >/dev/null
        fi
      ''}

      exec ${lib.escapeShellArgs qemuArgs} \
        -name "${name}" \
        ${lib.optionalString (persistentDiskSize != null) ''
        -drive if=virtio,format=qcow2,file="$persist_disk" \
      ''}
        -device "virtio-net-pci,netdev=vlan${toString vlan},mac=${mac}" \
        -netdev "vde,id=vlan${toString vlan},sock=$TMPDIR/../vde${toString vlan}.ctl" \
        "$@"
    '';

  mkVmDerivation = {
    name,
    config,
    persistentDiskSize ? null,
  }:
    pkgs.runCommand "finix-vm-${name}"
    {
      preferLocalBuild = true;
      meta.mainProgram = "run-${name}-vm";
    }
    ''
      mkdir -p $out/bin
      ln -s ${config.system.topLevel} $out/system
      ln -s ${mkVmScript {
        inherit name config persistentDiskSize;
      }} $out/bin/run-${name}-vm
    '';

  mkTest = {
    name,
    nodes,
    testScript,
    extraDriverArgs ? [],
    persistentDiskSize ? null,
  }: let
    evaluatedNodes = lib.mapAttrs (mkVm evaluatedNodes) nodes;
    vms = lib.mapAttrs (nodeName: nodeEval:
      mkVmDerivation {
        name = nodeName;
        config = nodeEval.config;
        inherit persistentDiskSize;
      })
    evaluatedNodes;
    vmNames = builtins.attrNames vms;
    vmStartScripts = map (vmName: "${vms.${vmName}}/bin/run-${vmName}-vm") vmNames;
    vlans = lib.unique (lib.mapAttrsToList (_: nodeEval: nodeEval.config.testing.network.vlan) evaluatedNodes);
    testScriptString =
      if builtins.isFunction testScript
      then testScript {nodes = evaluatedNodes;}
      else testScript;
    pythonTestScript = pkgs.writeText "test-${name}.py" testScriptString;
    driver =
      pkgs.runCommand "finix-test-driver-${name}"
      {
        nativeBuildInputs = [pkgs.makeWrapper];
        buildInputs = [testDriver];
        passthru = {
          inherit vms evaluatedNodes;
          nodes = evaluatedNodes;
        };
        meta.mainProgram = "finix-test-driver";
      }
      ''
        mkdir -p $out/bin
        cp ${pythonTestScript} $out/test-script
        makeWrapper ${testDriver}/bin/nixos-test-driver $out/bin/finix-test-driver \
          --set testScript "$out/test-script" \
          --add-flags "--vm-names ${lib.concatStringsSep " " vmNames}" \
          --add-flags "--vm-start-scripts ${lib.concatStringsSep " " vmStartScripts}" \
          --add-flags "--container-names" \
          --add-flags "--container-start-scripts" \
          --add-flags "--vlans ${lib.concatStringsSep " " (map toString vlans)}" \
          ${lib.escapeShellArgs (lib.concatMap (arg: ["--add-flags" arg]) extraDriverArgs)}
      '';
  in
    pkgs.runCommand "finix-test-${name}"
    {
      nativeBuildInputs = [pkgs.vde2];
      passthru = {
        inherit driver vms;
        driverInteractive = driver;
      };
    }
    ''
      mkdir -p $out
      export LOGFILE=/dev/null
      ${driver}/bin/finix-test-driver -o $out
    '';

  smokeTest = mkTest {
    name = "finix-server-vm-smoke";

    nodes.server = {
      imports = [commonModule];
    };

    testScript = ''
      start_all()

      server.wait_for_console_text("entering runlevel 2")
      server.wait_until_succeeds("initctl cond get service/sshd/running", timeout=60)
      server.wait_until_succeeds("initctl cond get service/dockerd/running", timeout=60)
      server.wait_until_succeeds("initctl cond get service/tailscaled/running", timeout=60)
      server.wait_until_succeeds("initctl cond get service/postgresql/running", timeout=120)
      server.wait_until_succeeds("initctl cond get task/postgresql-setup/success", timeout=120)
      server.wait_until_succeeds("initctl cond get service/syncthing/running", timeout=60)
      server.wait_until_succeeds("initctl cond get task/syncthing-setup/success", timeout=180)
      server.wait_until_succeeds("initctl cond get task/forgejo-setup/success", timeout=60)
      server.wait_until_succeeds("initctl cond get service/forgejo/running", timeout=60)
      server.wait_until_succeeds("initctl cond get service/nginx/running", timeout=60)
      server.wait_until_succeeds("initctl cond get service/n8n/running", timeout=60)
      server.wait_until_succeeds("initctl cond get task/mediamtx-env/success", timeout=60)
      server.wait_until_succeeds("initctl cond get service/mediamtx/running", timeout=60)

      server.wait_until_succeeds("ss -ltn | grep ':22 '", timeout=60)
      server.wait_until_succeeds("ss -ltn | grep ':2222 '", timeout=60)
      server.wait_until_succeeds("ss -ltn | grep ':3000 '", timeout=60)
      server.wait_until_succeeds("ss -ltn | grep ':5678 '", timeout=60)
      server.wait_until_succeeds("ss -ltn | grep ':8384 '", timeout=60)
      server.wait_until_succeeds("ss -ltnu | grep ':4200 '", timeout=60)
      server.wait_until_succeeds("test -S /run/docker.sock", timeout=60)
      server.wait_until_succeeds("test -S /run/tailscale/tailscaled.sock", timeout=60)

      server.succeed("id y0usaf")
      server.succeed("docker --host unix:///run/docker.sock version")
      server.succeed("PGHOST=/run/postgresql PGUSER=postgres psql -d postgres -tAc 'SELECT 1' | grep 1")
      server.succeed("PGHOST=/run/postgresql PGUSER=postgres psql -d postgres -tAc \"SELECT 1 FROM pg_database WHERE datname='forgejo'\" | grep 1")
      server.succeed("curl -sfL http://127.0.0.1:3000/ >/tmp/forgejo.html")
      server.succeed("curl -s -o /tmp/n8n.html -w '%{http_code}' http://127.0.0.1:5678/ | grep -E '^(200|301|302|401|403|404)$'")
      server.succeed("curl -sf http://127.0.0.1:8384/rest/noauth/health")
      server.succeed("curl -s -H 'Host: syncthing-server' -o /tmp/nginx-syncthing.html -w '%{http_code}' http://127.0.0.1/ | grep -E '^(200|301|302|403)$'")
      server.succeed("${pkgs.libxml2}/bin/xmllint --xpath 'string(configuration/gui/apikey)' /home/y0usaf/.config/syncthing/config.xml >/tmp/syncthing-api-key")
      server.succeed("api_key=$(cat /tmp/syncthing-api-key); curl -sf -H \"X-API-Key: $api_key\" http://127.0.0.1:8384/rest/config/folders | ${pkgs.jq}/bin/jq -e 'map(.id) | index(\"bv79n-fh4kx\") != null'")
      server.succeed("tailscale --socket /run/tailscale/tailscaled.sock version")
    '';
  };

  impermanenceTest = mkTest {
    name = "finix-server-vm-impermanence";
    persistentDiskSize = "8G";

    nodes.server = {
      imports = [
        commonModule
        impermanenceModule
      ];
    };

    testScript = ''
      def wait_server_boot(timeout=240):
          server.wait_for_console_text("entering runlevel 2")
          checks = [
              ("initctl cond get service/sshd/running", 120),
              ("initctl cond get service/dockerd/running", 120),
              ("initctl cond get service/tailscaled/running", 120),
              ("initctl cond get service/postgresql/running", 180),
              ("initctl cond get task/postgresql-setup/success", 180),
              ("initctl cond get service/syncthing/running", 120),
              ("initctl cond get task/syncthing-setup/success", 180),
              ("initctl cond get task/forgejo-setup/success", 180),
              ("initctl cond get service/forgejo/running", 180),
              ("initctl cond get service/nginx/running", 120),
              ("initctl cond get service/n8n/running", 180),
              ("initctl cond get task/mediamtx-env/success", 120),
              ("initctl cond get service/mediamtx/running", 120),
              ("findmnt -no FSTYPE /persist | grep btrfs", 120),
              ("findmnt -no FSTYPE /home | grep btrfs", 120),
              ("findmnt -no OPTIONS /home | grep @home", 120),
              ("findmnt -no OPTIONS /home/y0usaf/Music | grep @music", 120),
          ]
          for command, command_timeout in checks:
              server.wait_until_succeeds(command, timeout=command_timeout)

      server.start(allow_reboot=True)
      wait_server_boot()

      server.succeed("mkdir -p /persist/checks")
      server.succeed("test -L /var/lib/postgresql && test \"$(readlink /var/lib/postgresql)\" = /persist/var/lib/postgresql")
      server.succeed("test -L /home/y0usaf/.hermes && test \"$(readlink /home/y0usaf/.hermes)\" = /persist/home/y0usaf/.hermes")
      server.succeed("cp /etc/machine-id /persist/checks/machine-id")
      server.succeed("sha256sum /var/lib/sshd/ssh_host_ed25519_key.pub | cut -d' ' -f1 > /persist/checks/ssh-host-key.sha")
      server.succeed("sha256sum /var/lib/forgejo/custom/conf/secret_key | cut -d' ' -f1 > /persist/checks/forgejo-secret.sha")
      server.succeed("${pkgs.libxml2}/bin/xmllint --xpath 'string(configuration/gui/apikey)' /home/y0usaf/.config/syncthing/config.xml > /persist/checks/syncthing-api-key")
      server.succeed("printf 'persist\n' > /persist/checks/persist-root.txt")
      server.succeed("printf 'volatile\n' > /home/y0usaf/volatile.txt")
      server.succeed("printf 'persistent-home\n' > /home/y0usaf/.hermes/persist.txt")
      server.succeed("printf 'music\n' > /home/y0usaf/Music/persist-music.txt")
      server.succeed("docker --host unix:///run/docker.sock volume create persistvol")
      server.wait_until_succeeds("test -d /var/lib/docker/volumes/persistvol", timeout=60)
      server.succeed("PGHOST=/run/postgresql PGUSER=postgres psql -d postgres -c \"CREATE TABLE IF NOT EXISTS reboot_test(value text); TRUNCATE reboot_test; INSERT INTO reboot_test VALUES ('persisted');\"")
      server.succeed("sync")

      server.reboot()
      wait_server_boot()

      server.succeed("cmp /etc/machine-id /persist/checks/machine-id")
      server.succeed("test \"$(sha256sum /var/lib/sshd/ssh_host_ed25519_key.pub | cut -d' ' -f1)\" = \"$(cat /persist/checks/ssh-host-key.sha)\"")
      server.succeed("test \"$(sha256sum /var/lib/forgejo/custom/conf/secret_key | cut -d' ' -f1)\" = \"$(cat /persist/checks/forgejo-secret.sha)\"")
      server.succeed("test \"$(${pkgs.libxml2}/bin/xmllint --xpath 'string(configuration/gui/apikey)' /home/y0usaf/.config/syncthing/config.xml)\" = \"$(cat /persist/checks/syncthing-api-key)\"")
      server.succeed("grep -Fx persist /persist/checks/persist-root.txt")
      server.succeed("test ! -e /home/y0usaf/volatile.txt")
      server.succeed("grep -Fx persistent-home /home/y0usaf/.hermes/persist.txt")
      server.succeed("grep -Fx music /home/y0usaf/Music/persist-music.txt")
      server.succeed("docker --host unix:///run/docker.sock volume ls | grep persistvol")
      server.succeed("PGHOST=/run/postgresql PGUSER=postgres psql -d postgres -tAc 'SELECT value FROM reboot_test' | grep persisted")
    '';
  };

  mkManualVmPackage = {
    name,
    systemConfig,
    persistentDiskPath ? null,
    persistentDiskSize ? null,
  }:
    pkgs.runCommand name {
      meta.mainProgram = "run-${name}";
    } ''
      mkdir -p $out/bin
      ln -s ${systemConfig.config.system.topLevel} $out/system
      cat > $out/bin/run-${name} <<'EOF'
      #!${pkgs.runtimeShell}
      set -e
      ${lib.optionalString (persistentDiskPath != null && persistentDiskSize != null) ''
        persist_disk="${persistentDiskPath}"
        mkdir -p "$(dirname "$persist_disk")"
        if ! [ -e "$persist_disk" ]; then
          ${systemConfig.config.virtualisation.qemu.package}/bin/qemu-img create -f qcow2 "$persist_disk" ${persistentDiskSize} >/dev/null
        fi
      ''}
      exec ${lib.escapeShellArgs systemConfig.config.virtualisation.qemu.argv} ${lib.optionalString (persistentDiskPath != null) ''-drive if=virtio,format=qcow2,file="$persist_disk"''} "$@"
      EOF
      chmod +x $out/bin/run-${name}
    '';
in {
  inherit impermanenceTest manualSystem smokeTest;

  impermanentVmPackage = mkManualVmPackage {
    name = "finix-server-impermanent-vm";
    systemConfig = impermanentManualSystem;
    persistentDiskPath = "\${XDG_STATE_HOME:-$HOME/.local/state}/finix-server-impermanent-vm/persist.qcow2";
    persistentDiskSize = "8G";
  };

  vmPackage = mkManualVmPackage {
    name = "finix-server-vm";
    systemConfig = manualSystem;
  };
}

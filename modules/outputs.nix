inputs: let
  system = "x86_64-linux";
  inherit (pkgs) lib;

  mkPkgs = cudaSupport:
    import (toString inputs.nixpkgs) {
      inherit system;
      config = {
        allowUnfree = true;
        inherit cudaSupport;
        permittedInsecurePackages = ["openclaw-2026.10.3"];
      };
      overlays = [
        inputs.claude-code-nix.overlays.default
        (_: _: {
          rush = inputs.rush.packages.${system}.default.overrideAttrs (old: {
            patches = (old.patches or []) ++ [./shell/rush-login-command.patch];
          });
          monstar = inputs.monstar.packages.${system}.default;
          ash = inputs.ash.packages.${system}.default;
        })
        (_: prev: {
          obs-studio-plugins =
            prev.obs-studio-plugins
            // {
              obs-vertical-canvas = prev.obs-studio-plugins.obs-vertical-canvas.overrideAttrs (old: {
                postPatch =
                  (old.postPatch or "")
                  + ''
                    sed -i '/find_qt(COMPONENTS Widgets COMPONENTS_LINUX Gui)/a find_package(Qt6 REQUIRED COMPONENTS GuiPrivate)' CMakeLists.txt
                  '';
              });
            };
        })
      ];
    };
  pkgs = mkPkgs false;

  mkFinixSystem = {
    modules,
    cudaSupport ? false,
  }:
    inputs.finix.lib.finixSystem {
      inherit lib;
      specialArgs.flakeInputs = inputs;
      modules =
        [
          {
            nixpkgs.pkgs =
              if cudaSupport
              then mkPkgs true
              else pkgs;
          }
          inputs.finix.nixosModules.bash
          inputs.finix.nixosModules.chronyd
          inputs.finix.nixosModules.dhcpcd
          inputs.finix.nixosModules.getty
          inputs.finix.nixosModules.openssh
          ./finix/sudo.nix
          inputs.finix.nixosModules.sysklogd
          ./finix/chrony.nix
          ./finix/common.nix
          ./finix/emudhra-distrust.nix
          ./finix/persist-order.nix
          ./finix/persistence.nix
        ]
        ++ modules;
    };

  nixFiles = dirs: builtins.filter (f: lib.hasSuffix ".nix" (toString f)) (builtins.concatMap lib.filesystem.listFilesRecursive dirs);
  graphicalModules = nixFiles [
    ./core
    ./desktop
    ./dev
    ./gaming
    ./shell
    ./tools
    ./user-services
    ./hosts/common
  ];

  baseModules = [
    inputs.finix.nixosModules.nix-daemon
    inputs.finix.nixosModules.nftables
    ./finix/diagnostics.nix
    inputs.manzil.finixModules.default
  ];

  hosts = {
    y0usaf-server = mkFinixSystem {
      modules =
        baseModules
        ++ [
          inputs.finix.nixosModules.cron
          inputs.finix.nixosModules.postgresql
          ./server/forgejo.nix
          ./server/mediamtx.nix
          ./server/syncthing.nix
          ./hosts/y0usaf-server/config.nix
          ./finix/tailscale.nix
          ./finix/static-net.nix
          ./hosts/y0usaf-server/hardware-config.nix
          ./hosts/y0usaf-server/boot.nix
          ./server/attic.nix
          ./server/amp-orb.nix
          ./server/packages.nix
          ./dev/ai/prompts/policy.nix
          ./dev/ai/claude-code.nix
          ./dev/ai/paseo.nix
          ./server/openclaw.nix
          ./tools/git.nix
          ./tools/tmux.nix
        ];
    };

    y0usaf-desktop = mkFinixSystem {
      cudaSupport = true;
      modules =
        baseModules
        ++ [
          inputs.finix.nixosModules.cron
          inputs.finix.nixosModules.networkmanager
          inputs.finix.nixosModules.limine
          ./finix/static-net.nix
          ./server/amp-orb.nix
        ]
        ++ graphicalModules
        ++ nixFiles [./hosts/y0usaf-desktop];
    };

    y0usaf-framework = mkFinixSystem {
      modules =
        baseModules
        ++ [
          inputs.finix.nixosModules.brightnessctl
          inputs.finix.nixosModules.docker
          inputs.finix.nixosModules.fwupd
          inputs.finix.nixosModules.networkmanager
          inputs.finix.nixosModules.power-profiles-daemon
          inputs.finix.nixosModules.zzz
        ]
        ++ graphicalModules
        ++ nixFiles [./hosts/y0usaf-framework];
    };
  };

  mkDeploy = {
    defaultHost,
    name,
    toplevel,
    sshHost ? null,
    sshPort ? null,
  }: let
    portStr = lib.optionalString (sshPort != null) (toString sshPort);
  in
    pkgs.writeShellScriptBin name ''
      set -euo pipefail

      host="''${1:-${defaultHost}}"
      action="''${2:-test}"
      case "$host" in
        *[!A-Za-z0-9_.:@-]*)
          echo "invalid host: $host" >&2
          exit 2
          ;;
      esac
      case "$action" in
        test|boot|switch) ;;
        *)
          echo "usage: ${name} [host] [test|boot|switch]" >&2
          exit 2
          ;;
      esac
      system_path='${toplevel}'
      remote_host="${
        if sshHost == null
        then "$host"
        else sshHost
      }"

      if [ "$host" != local ] && [ -n '${portStr}' ]; then
        export NIX_SSHOPTS='-p ${portStr} -o ControlPath=none'
        ssh_cmd=(ssh -p '${portStr}' -o ControlPath=none)
      else
        ssh_cmd=(ssh)
      fi

      if [ "$host" = local ]; then
        if [ -d /run/systemd/system ]; then
          echo "${name}: refusing local $action under systemd; target a live Finix host over ssh" >&2
          exit 1
        fi
        sudo "$system_path/sw/bin/nix-store" --realise "$system_path" \
          --add-root /nix/var/nix/gcroots/finix-persistent >/dev/null
        if [ "$action" != test ]; then
          sudo "$system_path/sw/bin/nix-env" -p /nix/var/nix/profiles/system --set "$system_path"
        fi
        sudo "$system_path/bin/switch-to-configuration" "$action"
        exit 0
      fi

      remote_store="ssh://$remote_host${lib.optionalString (sshPort != null) ":${toString sshPort}"}?remote-program=/run/current-system/sw/bin/nix-store"

      echo "==> copying persistent finix closure to $remote_host"
      nix copy --to "$remote_store" "$system_path"

      echo "==> rooting persistent closure"
      "''${ssh_cmd[@]}" "$remote_host" \
        "/run/wrappers/bin/sudo '$system_path/sw/bin/nix-store' --realise '$system_path' --add-root /nix/var/nix/gcroots/finix-persistent"

      if [ "$action" != test ]; then
        echo "==> registering system profile generation"
        "''${ssh_cmd[@]}" "$remote_host" \
          "/run/wrappers/bin/sudo /run/current-system/sw/bin/nix-env -p /nix/var/nix/profiles/system --set '$system_path'"
      fi

      echo "==> finix switch-to-configuration $action"
      "''${ssh_cmd[@]}" "$remote_host" \
        "/run/wrappers/bin/sudo '$system_path/bin/switch-to-configuration' '$action'"
      if [ "$action" != test ]; then
        "''${ssh_cmd[@]}" "$remote_host" \
          "/run/wrappers/bin/sudo /run/current-system/sw/bin/sync"
      fi
    '';
in {
  nixosConfigurations = hosts // {y0usaf-server-finix = hosts.y0usaf-server;};

  nixOnDroidConfigurations.default = inputs."nix-on-droid".lib.nixOnDroidConfiguration {
    pkgs = import (toString inputs.nixpkgs) {
      system = "aarch64-linux";
    };
    extraSpecialArgs = {
      flakeInputs = inputs;
    };
    modules = [
      ./hosts/android-phone/nix-on-droid.nix
    ];
  };

  finixConfigurations = hosts;

  packages.${system} = {
    finix-server-persistent-deploy = mkDeploy {
      name = "finix-server-persistent-deploy";
      toplevel = hosts.y0usaf-server.config.system.topLevel;
      defaultHost = "server";
      sshHost = hosts.y0usaf-server.config.networking.hostName;
      sshPort = builtins.head hosts.y0usaf-server.config.services.openssh.settings.Port;
    };
    finix-desktop-deploy = mkDeploy {
      name = "finix-desktop-deploy";
      toplevel = hosts.y0usaf-desktop.config.system.topLevel;
      defaultHost = "local";
    };
    finix-frame-deploy = import ./hosts/steam-frame/deploy.nix {inherit inputs pkgs;};
    drift = import ./drift.nix {inherit lib pkgs hosts;};
    inherit (hosts.y0usaf-desktop.config.system.build) chatgpt p4g-setup;
    tomoe = inputs.tomoe.packages.${system}.default;
  };

  checks.${system} = lib.mapAttrs' (name: host: lib.nameValuePair name host.config.system.build.toplevel) hosts;

  formatter.${system} = inputs.nixpkgs.legacyPackages.${system}.alejandra;
}

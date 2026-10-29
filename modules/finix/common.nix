{
  config,
  lib,
  pkgs,
  ...
}: let
  user = config.user.name;
  persistedSshDir = "/persist/etc/ssh";
in {
  options.user = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "y0usaf";
      description = "Primary username for the system";
    };

    homeDirectory = lib.mkOption {
      type = lib.types.path;
      default = "/home/${config.user.name}";
      description = "Home directory path for the user";
    };

    uid = lib.mkOption {
      type = lib.types.int;
      default = 1000;
      description = "Numeric uid of the primary user. The persisted home is owned by this number, so changing it renumbers every file under /persist/home.";
    };
  };

  config = {
    time.timeZone = "America/Toronto";

    environment.etc."profile.d/system-path.sh".text = ''
      case ":$PATH:" in
        *:/run/current-system/sw/bin:*) ;;
        *)
          export PATH="$PATH:/etc/profiles/per-user/${user}/bin:${config.user.homeDirectory}/.nix-profile/bin:/run/wrappers/bin:/run/current-system/sw/bin"
          ;;
      esac
    '';

    networking.hosts = {
      "127.0.0.1" = ["localhost"];
      "::1" = ["localhost"];
      "127.0.0.2" = [config.networking.hostName];
    };

    services = {
      sysklogd = {
        enable = true;
        extraConfig = ''
          rotate_size 256M
          rotate_count 10
        '';
      };
      openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "no";
          HostKey = lib.mkForce ["${persistedSshDir}/ssh_host_ed25519_key"];
          AuthorizedKeysFile = lib.mkForce ["${persistedSshDir}/authorized_keys.d/%u"];
        };
      };
      nix-daemon = {
        enable = true;
        settings.trusted-users = lib.mkForce ["root" user];
      };
    };

    programs.bash.enable = true;

    manzil.forceByDefault = true;

    finit.tasks = {
      remount-nix-store.enable = false;
      ssh-keygen.command = lib.mkForce (pkgs.writeShellScript "check-host-keys" ''
        [ -s ${persistedSshDir}/ssh_host_ed25519_key ]
      '');
      efi-pstore-drain = {
        description = "drain EFI pstore dumps so the NVRAM stays writable";
        command = pkgs.writeShellScript "efi-pstore-drain" ''
          export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.e2fsprogs pkgs.util-linux]}
          vars=/sys/firmware/efi/efivars
          for _ in $(seq 1 30); do
            mountpoint -q "$vars" && break
            sleep 1
          done
          mountpoint -q "$vars" || exit 0
          n=0
          for f in "$vars"/dump-*; do
            [ -e "$f" ] || continue
            chattr -i "$f" 2>/dev/null || true
            rm -f "$f" && n=$((n + 1))
          done
          [ "$n" -eq 0 ] || echo "efi-pstore-drain: removed $n stale crash dumps"
        '';
        log = true;
      };
    };

    system.activation.scripts.persistentSshAuthorizedKeys = {
      deps = ["etc"];
      text = ''
        ${pkgs.coreutils}/bin/install -d -m 0755 ${persistedSshDir}/authorized_keys.d
        ${pkgs.coreutils}/bin/install -m 0644 -o root -g root \
          /etc/ssh/authorized_keys.d/${user} \
          ${persistedSshDir}/authorized_keys.d/${user}
      '';
    };

    environment = {
      etc."ssh/authorized_keys.d/y0usaf".text = ''
        ${lib.removeSuffix "\n" (builtins.readFile ../hosts/y0usaf-desktop/user-ssh.pub)}
        ${lib.removeSuffix "\n" (builtins.readFile ../hosts/y0usaf-framework/user-ssh.pub)}
        ${lib.removeSuffix "\n" (builtins.readFile ../hosts/y0usaf-server/user-ssh.pub)}
        ${lib.removeSuffix "\n" (builtins.readFile ../hosts/android-phone/user-ssh.pub)}
      '';
      shells = [
        "/run/current-system/sw/bin/rush"
        "${pkgs.rush}/bin/rush"
        "/run/current-system/sw/bin/ash"
        "${pkgs.ash}/bin/ash"
      ];
      systemPackages = [
        pkgs.curl
        pkgs.iproute2
        pkgs.iputils
        pkgs.procps
        pkgs.util-linux
        pkgs.vim
        pkgs.rush
        pkgs.ash
      ];
    };

    users.users.y0usaf = {
      isNormalUser = true;
      inherit (config.user) uid;
      home = "/home/y0usaf";
      shell = "${pkgs.rush}/bin/rush";
      extraGroups = ["wheel"];
      passwordFile = "/persist/secrets/password-hashes/${user}";
    };
  };
}

{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.finix.persistence.identity;
  user = config.user.name;
  persistedSshDir = "${cfg.root}/etc/ssh";
in {
  options.finix.persistence.identity = {
    enable = lib.mkEnableOption "persistent Finix user and SSH identity";
    root = lib.mkOption {
      type = lib.types.str;
      default = "/persist";
      description = "Root of persistent system state.";
    };
    userPasswordFile = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.root}/secrets/password-hashes/${user}";
      description = "Persistent password hash for the primary user.";
    };
    restoreMachineId = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Restore /etc/machine-id from persistent state during activation.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh.settings = {
      HostKey = lib.mkForce ["${persistedSshDir}/ssh_host_ed25519_key"];
      AuthorizedKeysFile = lib.mkForce ["${persistedSshDir}/authorized_keys.d/%u"];
      UsePAM = lib.mkForce true;
      StrictModes = lib.mkForce true;
    };

    users.users.${user} = {
      password = lib.mkForce null;
      passwordFile = lib.mkForce cfg.userPasswordFile;
    };

    system.activation.scripts = {
      persistentSshAuthorizedKeys = {
        deps = ["etc"];
        text = ''
          ${pkgs.coreutils}/bin/install -d -m 0755 ${persistedSshDir}/authorized_keys.d
          ${pkgs.coreutils}/bin/install -m 0644 -o root -g root \
            /etc/ssh/authorized_keys.d/${user} \
            ${persistedSshDir}/authorized_keys.d/${user}
        '';
      };
      persistentMachineId = lib.mkIf cfg.restoreMachineId {
        text = ''
          if [ -s ${cfg.root}/etc/machine-id ]; then
            ${pkgs.coreutils}/bin/install -m 0444 ${cfg.root}/etc/machine-id /etc/machine-id
          fi
        '';
      };
    };

    finit.tasks.ssh-keygen.command = lib.mkForce (pkgs.writeShellScript "check-host-keys" ''
      [ -s ${persistedSshDir}/ssh_host_ed25519_key ]
    '');
  };
}

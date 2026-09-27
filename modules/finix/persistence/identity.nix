{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.finix.persistence.identity;
  user = config.user.name;
  persistedSshDir = "/persist/etc/ssh";
in {
  options.finix.persistence.identity = {
    restoreMachineId = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Restore /etc/machine-id from persistent state during activation.";
    };
  };

  config = {
    services.openssh.settings = {
      HostKey = lib.mkForce ["${persistedSshDir}/ssh_host_ed25519_key"];
      AuthorizedKeysFile = lib.mkForce ["${persistedSshDir}/authorized_keys.d/%u"];
      UsePAM = lib.mkForce true;
      StrictModes = lib.mkForce true;
    };

    users.users.${user}.passwordFile = lib.mkForce "/persist/secrets/password-hashes/${user}";

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
          if [ -s /persist/etc/machine-id ]; then
            ${pkgs.coreutils}/bin/install -m 0444 /persist/etc/machine-id /etc/machine-id
          fi
        '';
      };
    };

    finit.tasks.ssh-keygen.command = lib.mkForce (pkgs.writeShellScript "check-host-keys" ''
      [ -s ${persistedSshDir}/ssh_host_ed25519_key ]
    '');
  };
}

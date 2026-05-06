{
  config,
  pkgs,
  ...
}: let
  sshdPort = 8022;
  sshdTmpDirectory = "${config.user.home}/sshd-tmp";
  sshdDirectory = "${config.user.home}/sshd";
  authorizedKeys = pkgs.writeText "android-phone-authorized_keys" ''
    ${builtins.readFile ../y0usaf-desktop/user-ssh.pub}
    ${builtins.readFile ../y0usaf-server/user-ssh.pub}
  '';
in {
  system.stateVersion = "24.05";

  environment = {
    packages =
      [
        (pkgs.writeShellScriptBin "sshd-start" ''
          exec ${pkgs.openssh}/bin/sshd -f "${sshdDirectory}/sshd_config" -D -e
        '')
      ]
      ++ (with pkgs; [
        bashInteractive
        coreutils
        curl
        gitMinimal
        openssh
        vim
      ]);
    etcBackupExtension = ".bak";
    motd = ''
      minimal nix-on-droid profile
      ssh: ssh -p ${toString sshdPort} nix-on-droid@100.93.111.41
    '';
  };

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  build.activation.sshd = ''
        $DRY_RUN_CMD mkdir $VERBOSE_ARG --parents "${config.user.home}/.ssh"
        $DRY_RUN_CMD cp ${authorizedKeys} "${config.user.home}/.ssh/authorized_keys"
        $DRY_RUN_CMD chmod 700 "${config.user.home}/.ssh"
        $DRY_RUN_CMD chmod 600 "${config.user.home}/.ssh/authorized_keys"

        if [ ! -d "${sshdDirectory}" ]; then
          $DRY_RUN_CMD rm $VERBOSE_ARG --recursive --force "${sshdTmpDirectory}"
          $DRY_RUN_CMD mkdir $VERBOSE_ARG --parents "${sshdTmpDirectory}"

          $VERBOSE_ECHO "Generating ssh host key..."
          $DRY_RUN_CMD ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f "${sshdTmpDirectory}/ssh_host_ed25519_key" -N ""

          $VERBOSE_ECHO "Writing sshd_config..."
          $DRY_RUN_CMD cat > "${sshdTmpDirectory}/sshd_config" <<EOF
    HostKey ${sshdDirectory}/ssh_host_ed25519_key
    Port ${toString sshdPort}
    PasswordAuthentication no
    PubkeyAuthentication yes
    AuthorizedKeysFile ${config.user.home}/.ssh/authorized_keys
    PidFile ${sshdDirectory}/sshd.pid
    EOF

          $DRY_RUN_CMD mv $VERBOSE_ARG "${sshdTmpDirectory}" "${sshdDirectory}"
        fi
  '';
}

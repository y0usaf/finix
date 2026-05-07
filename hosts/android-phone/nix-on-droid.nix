{
  config,
  flakeInputs,
  lib,
  pkgs,
  ...
}: let
  phoneUser = config.user.userName;
  homeDir = config.user.home;
  sshdPort = 8022;
  sshdTmpDirectory = "${homeDir}/sshd-tmp";
  sshdDirectory = "${homeDir}/sshd";

  gitName = "y0usaf";
  gitEmail = "OA99@Outlook.com";
  tokensKey = "${homeDir}/Tokens/id_rsa_${gitName}";
  manzil = flakeInputs.manzil.packages.${pkgs.stdenv.hostPlatform.system}.default;

  readKey = path: lib.removeSuffix "\n" (builtins.readFile path);
  authorizedKeys = pkgs.writeText "android-phone-authorized_keys" ''
    ${builtins.readFile ../y0usaf-desktop/user-ssh.pub}
    ${builtins.readFile ../y0usaf-server/user-ssh.pub}
  '';
  knownHostsText =
    (lib.concatStringsSep "\n" (
      lib.mapAttrsToList (host: key: "${host} ${key}") {
        "100.93.111.41" = readKey ./host-ssh-ed25519.pub;
        "192.168.2.34" = readKey ./host-ssh-ed25519.pub;
        "android-phone" = readKey ./host-ssh-ed25519.pub;
        "desktop" = readKey ../y0usaf-desktop/host-ssh-ed25519.pub;
        "server" = readKey ../y0usaf-server/host-ssh-ed25519.pub;
        "y0usaf-desktop" = readKey ../y0usaf-desktop/host-ssh-ed25519.pub;
        "y0usaf-server" = readKey ../y0usaf-server/host-ssh-ed25519.pub;
      }
    ))
    + "\n";

  mkTextFile = name: text: {
    source = pkgs.writeText "android-phone-${name}" text;
    clobber = true;
  };
  manzilFiles = {
    ".config/git/config" = mkTextFile "git-config" (lib.generators.toGitINI {
      user = {
        name = gitName;
        email = gitEmail;
      };
      core.editor = "vim";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      url."git@github.com:".pushInsteadOf = "https://github.com/";
    });

    ".config/nushell/config.nu" = mkTextFile "nushell-config" ''
      $env.config.show_banner = false
      $env.config.history.max_size = 10000
      $env.config.history.file_format = "sqlite"

      alias la = ls -a
      alias ll = ls -l
      alias lla = ls -la
    '';

    ".config/nushell/env.nu" = mkTextFile "nushell-env" ''
      $env.EDITOR = "vim"
      $env.VISUAL = "vim"
      $env.SHELL = "${pkgs.nushell}/bin/nu"
      $env.XDG_CACHE_HOME = "${homeDir}/.cache"
      $env.XDG_CONFIG_HOME = "${homeDir}/.config"
      $env.XDG_DATA_HOME = "${homeDir}/.local/share"
      $env.XDG_STATE_HOME = "${homeDir}/.local/state"
    '';

    ".ssh/config" = mkTextFile "ssh-config" ''
      AddKeysToAgent yes
      ServerAliveInterval 60
      ServerAliveCountMax 5
      SetEnv TERM=xterm-256color

      Host server y0usaf-server
          HostName y0usaf-server
          User y0usaf
          IdentityFile ${homeDir}/.ssh/id_ed25519
          IdentitiesOnly yes
          ForwardAgent yes

      Host desktop y0usaf-desktop
          HostName y0usaf-desktop
          Port 2222
          User y0usaf
          IdentityFile ${tokensKey}
          ForwardAgent yes

      Host github.com
          HostName github.com
          User git
          IdentityFile ${tokensKey}
          ForwardAgent yes
    '';

    ".ssh/known_hosts" = mkTextFile "known-hosts" knownHostsText;
  };
  manzilManifest = pkgs.writeText "android-phone-manzil-manifest.json" (builtins.toJSON {
    files =
      lib.mapAttrsToList (target: file: {
        target = "${homeDir}/${target}";
        source = "${file.source}";
        inherit (file) clobber;
      })
      manzilFiles;
  });
in {
  system.stateVersion = "24.05";
  time.timeZone = "America/Toronto";

  user.shell = "${pkgs.nushell}/bin/nu";

  environment = {
    packages =
      [
        manzil
        (pkgs.writeShellScriptBin "sshd-start" ''
          exec ${pkgs.openssh}/bin/sshd -f "${sshdDirectory}/sshd_config" -D -e
        '')
      ]
      ++ (with pkgs; [
        curl
        gitMinimal
        nushell
        openssh
        vim
      ]);
    etcBackupExtension = ".bak";
    motd = ''
      minimal nix-on-droid profile
      shell: nu
      ssh: ssh -p ${toString sshdPort} ${phoneUser}@100.93.111.41
    '';
    sessionVariables = {
      EDITOR = "vim";
      VISUAL = "vim";
      SHELL = "${pkgs.nushell}/bin/nu";
    };
  };

  nix = {
    registry.nixpkgs.flake = flakeInputs.nixpkgs;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  build.activation = {
    manzil = ''
      stateDir="${homeDir}/.local/state/manzil"
      manifest="$stateDir/manifest-${phoneUser}.json"

      if [ -n "''${DRY_RUN:-}" ]; then
        echo "would run: ${manzil}/bin/manzil ${manzilManifest} $manifest"
      else
        mkdir -p "$stateDir"
        if ${manzil}/bin/manzil ${manzilManifest} "$manifest"; then
          install -m 0644 ${manzilManifest} "$manifest"
        else
          echo "manzil: linker failed; state not updated" >&2
          exit 1
        fi
      fi
    '';

    sshd = ''
            $DRY_RUN_CMD mkdir $VERBOSE_ARG --parents "${homeDir}/.ssh"
            $DRY_RUN_CMD cp ${authorizedKeys} "${homeDir}/.ssh/authorized_keys"
            $DRY_RUN_CMD chmod 700 "${homeDir}/.ssh"
            $DRY_RUN_CMD chmod 600 "${homeDir}/.ssh/authorized_keys"

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
      AuthorizedKeysFile ${homeDir}/.ssh/authorized_keys
      PidFile ${sshdDirectory}/sshd.pid
      EOF

              $DRY_RUN_CMD mv $VERBOSE_ARG "${sshdTmpDirectory}" "${sshdDirectory}"
            fi
    '';
  };
}

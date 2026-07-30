{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  phoneUser = config.user.userName;
  homeDir = config.user.home;
  sshdPort = 8022;
  sshdTmpDirectory = "${homeDir}/sshd-tmp";
  sshdDirectory = "${homeDir}/sshd";

  gitName = "y0usaf";
  tokensKey = "${homeDir}/Tokens/id_rsa_${gitName}";
  manzil = flakeInputs.manzil.packages."${pkgs.stdenv.hostPlatform.system}".default;

  readKey = path: lib.removeSuffix "\n" (builtins.readFile path);

  mkTextFile = name: text: {
    source = pkgs.writeText "android-phone-${name}" text;
    clobber = true;
  };
  manzilManifest = pkgs.writeText "android-phone-manzil-manifest.json" (builtins.toJSON {
    files =
      lib.mapAttrsToList (target: file: {
        target = "${homeDir}/${target}";
        source = "${file.source}";
        inherit (file) clobber;
      })
      {
        ".config/git/config" = mkTextFile "git-config" (lib.generators.toGitINI {
          user = {
            name = gitName;
            email = "OA99@Outlook.com";
          };
          core.editor = "vim";
          init.defaultBranch = "main";
          pull.rebase = true;
          push.autoSetupRemote = true;
          url."git@github.com:" = {
            insteadOf = "https://github.com/";
            pushInsteadOf = "https://github.com/";
          };
        });

        # nix-on-droid has no /etc/profile.d session-vars drop-in, so the XDG
        # exports live here rather than in environment.sessionVariables.
        ".bashrc" = mkTextFile "bashrc" ''
          case $- in
            *i*) ;;
            *) return ;;
          esac

          export EDITOR=vim
          export VISUAL=vim
          export XDG_CACHE_HOME="${homeDir}/.cache"
          export XDG_CONFIG_HOME="${homeDir}/.config"
          export XDG_DATA_HOME="${homeDir}/.local/share"
          export XDG_STATE_HOME="${homeDir}/.local/state"

          HISTSIZE=10000
          HISTFILESIZE=10000
          HISTCONTROL=ignoreboth:erasedups
          shopt -s histappend checkwinsize

          alias la="ls -a"
          alias ll="ls -l"
          alias lla="ls -la"
        '';

        ".bash_profile" = mkTextFile "bash-profile" ''
          [ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
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

        ".ssh/known_hosts" = mkTextFile "known-hosts" ((lib.concatStringsSep "\n" (
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
          + "\n");
      };
  });
in {
  system.stateVersion = "24.05";
  time.timeZone = "America/Toronto";

  user.shell = "${pkgs.bashInteractive}/bin/bash";

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
        bashInteractive
        openssh
        vim
      ]);
    etcBackupExtension = ".bak";
    motd = ''
      minimal nix-on-droid profile
      shell: bash
      ssh: ssh -p ${toString sshdPort} ${phoneUser}@100.93.111.41
    '';
    sessionVariables = {
      EDITOR = "vim";
      VISUAL = "vim";
      SHELL = "${pkgs.bashInteractive}/bin/bash";
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
            $DRY_RUN_CMD cp ${pkgs.writeText "android-phone-authorized_keys" ''
        ${builtins.readFile ../y0usaf-desktop/user-ssh.pub}
        ${builtins.readFile ../y0usaf-server/user-ssh.pub}
      ''} "${homeDir}/.ssh/authorized_keys"
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

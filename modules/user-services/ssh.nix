{
  config,
  lib,
  pkgs,
  ...
}: let
  userName = config.user.name;
  homeDir = config.user.homeDirectory;
in {
  options.user.services.ssh = {
    enable = lib.mkEnableOption "SSH configuration module";
  };
  config = lib.mkIf config.user.services.ssh.enable {
    environment.systemPackages = [
      pkgs.openssh
    ];
    manzil.users."${userName}".files = {
      ".ssh/config" = {
        text = ''
          AddKeysToAgent yes
          ServerAliveInterval 60
          ServerAliveCountMax 5
          ControlMaster auto
          ControlPath %d/.ssh/master-%r@%h:%p
          ControlPersist 10m
          SetEnv TERM=xterm-256color
          Host server y0usaf-server
              HostName y0usaf-server
              Port 2200
              User ${userName}
              IdentityFile ${homeDir}/.ssh/id_ed25519
              IdentitiesOnly yes
              ForwardAgent yes

          Host rescue server-ts
              HostName 100.105.204.116
              User ${userName}
              IdentityFile ${homeDir}/.ssh/id_ed25519
              StrictHostKeyChecking accept-new
              UserKnownHostsFile ${homeDir}/.ssh/known_hosts.tailscale

          Host rescue-root
              HostName 100.105.204.116
              User root
              StrictHostKeyChecking accept-new
              UserKnownHostsFile ${homeDir}/.ssh/known_hosts.tailscale

          Host desktop y0usaf-desktop
              HostName y0usaf-desktop
              Port 2222
              User ${userName}
              IdentityFile ${homeDir}/.ssh/id_ed25519
              IdentitiesOnly yes
              ForwardAgent yes

          Host android-phone phone
              HostName 100.93.111.41
              Port 8022
              User nix-on-droid
              IdentityFile ${homeDir}/.ssh/id_ed25519
              IdentitiesOnly yes
              ForwardAgent yes

          Host github.com
              HostName github.com
              User git
              IdentityFile ${homeDir}/Tokens/id_rsa_${userName}
              ForwardAgent yes

          Host forgejo
              HostName y0usaf-server
              Port 2222
              User forgejo
              IdentityFile ${homeDir}/Tokens/id_rsa_${userName}
              IdentitiesOnly yes
        '';
      };
    };
    user.shell.rcExtra = lib.mkAfter ''
      export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent"
    '';
  };
}

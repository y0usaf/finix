{
  config,
  lib,
  pkgs,
  ...
}: let
  userName = config.user.name;
  homeDir = config.user.homeDirectory;
  zshEnabled = lib.attrByPath ["user" "shell" "zsh" "enable"] false config;
  nushellEnabled = lib.attrByPath ["user" "shell" "nushell" "enable"] false config;
in {
  options.user.services.ssh = {
    enable = lib.mkEnableOption "SSH configuration module";
  };
  config = lib.mkIf config.user.services.ssh.enable {
    environment.systemPackages = [
      pkgs.openssh
    ];
    bayt.users."${userName}".files =
      {
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
                User y0usaf
                IdentityFile ${homeDir}/.ssh/id_ed25519
                IdentitiesOnly yes
                ForwardAgent yes

            Host desktop
                HostName y0usaf-desktop
                Port 2222
                User y0usaf
                IdentityFile ${homeDir}/Tokens/id_rsa_${userName}
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
      }
      // lib.optionalAttrs zshEnabled {
        ".config/zsh/.zshenv" = {
          text = lib.mkAfter ''
            export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent"
          '';
        };
      }
      // lib.optionalAttrs nushellEnabled {
        ".config/nushell/env.nu" = {
          text = lib.mkAfter ''
            $env.SSH_AUTH_SOCK = $"($env.XDG_RUNTIME_DIR? | default '/run/user/1000')/ssh-agent"
          '';
        };
      };
    systemd.user.services.ssh-agent = {
      description = "SSH key agent";
      wantedBy = ["default.target"];
      serviceConfig = {
        Type = "forking";
        Environment = "SSH_AUTH_SOCK=%t/ssh-agent";
        ExecStart = "${pkgs.openssh}/bin/ssh-agent -a $SSH_AUTH_SOCK";
        ExecStartPost = "${pkgs.coreutils}/bin/systemctl --user set-environment SSH_AUTH_SOCK=$SSH_AUTH_SOCK";
      };
    };
  };
}

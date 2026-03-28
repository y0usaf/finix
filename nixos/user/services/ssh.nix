{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.services.ssh = {
    enable = lib.mkEnableOption "SSH configuration module";
  };
  config = lib.mkIf config.user.services.ssh.enable {
    environment.systemPackages = [
      pkgs.openssh
    ];
    bayt.users."${config.user.name}".files =
      {
        ".ssh/config" = {
          clobber = true;
          text = ''
            AddKeysToAgent yes
            ServerAliveInterval 60
            ServerAliveCountMax 5
            ControlMaster auto
            ControlPath %d/.ssh/master-%r@%h:%p
            ControlPersist 10m
            SetEnv TERM=xterm-256color
            Host server
                HostName y0usaf-server
                User y0usaf
                ForwardAgent yes

            Host desktop
                HostName y0usaf-desktop
                Port 2222
                User y0usaf
                IdentityFile ${config.user.homeDirectory}/Tokens/id_rsa_${config.user.name}
                ForwardAgent yes

            Host github.com
                HostName github.com
                User git
                IdentityFile ${config.user.homeDirectory}/Tokens/id_rsa_${config.user.name}
                ForwardAgent yes

            Host forgejo
                HostName y0usaf-server
                Port 2222
                User forgejo
                IdentityFile ${config.user.homeDirectory}/Tokens/id_rsa_${config.user.name}
                IdentitiesOnly yes
          '';
        };
      }
      // lib.optionalAttrs config.user.shell.zsh.enable {
        ".config/zsh/.zshenv" = {
          clobber = true;
          text = lib.mkAfter ''
            export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent"
          '';
        };
      }
      // lib.optionalAttrs config.user.shell.nushell.enable {
        ".config/nushell/env.nu" = {
          clobber = true;
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

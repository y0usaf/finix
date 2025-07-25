{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.services.ssh;
in {
  options.home.services.ssh = {
    enable = lib.mkEnableOption "SSH configuration module";
  };
  config = lib.mkIf cfg.enable {
    users.users.${config.user.name}.maid = {
      packages = with pkgs; [
        openssh
      ];
      file.home.".ssh/config".text = ''
        ForwardAgent yes
        AddKeysToAgent yes
        ServerAliveInterval 60
        ServerAliveCountMax 5
        ControlMaster auto
        ControlPath ~/.ssh/master-%r@%h:%p
        ControlPersist 10m
        SetEnv TERM=xterm-256color
        Host github.com
            HostName github.com
            User git
            IdentityFile ${config.user.tokensDirectory}/id_rsa_${config.user.name}
      '';
      systemd.services.ssh-agent = {
        description = "SSH key agent";
        wantedBy = ["default.target"];
        serviceConfig = {
          Type = "forking";
          Environment = "SSH_AUTH_SOCK=%t/ssh-agent";
          ExecStart = "${pkgs.openssh}/bin/ssh-agent -a $SSH_AUTH_SOCK";
          ExecStartPost = "${pkgs.coreutils}/bin/systemctl --user set-environment SSH_AUTH_SOCK=$SSH_AUTH_SOCK";
        };
      };
      file.home."{{xdg_config_home}}/zsh/.zshenv".text = lib.mkAfter ''
        export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent"
      '';
    };
  };
}

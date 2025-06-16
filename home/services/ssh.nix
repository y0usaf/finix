###############################################################################
# SSH Configuration (Maid Version)
# Configures SSH client and agent for secure remote connections
# - SSH client configuration with proper permissions
# - SSH key management with auto-adding to agent
# - GitHub connection setup
# - SSH agent service
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.services.ssh;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.services.ssh = {
    enable = lib.mkEnableOption "SSH configuration module";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Maid Configuration
    ###########################################################################
    users.users.y0usaf.maid = {
      packages = with pkgs; [
        openssh
      ];

      ###########################################################################
      # SSH Client Configuration
      ###########################################################################
      file.home.".ssh/config".text = ''
        # Global SSH Configuration
        ForwardAgent yes
        AddKeysToAgent yes
        ServerAliveInterval 60
        ServerAliveCountMax 5
        ControlMaster auto
        ControlPath ~/.ssh/master-%r@%h:%p
        ControlPersist 10m
        SetEnv TERM=xterm-256color

        # GitHub Configuration
        Host github.com
            HostName github.com
            User git
            IdentityFile ~/Tokens/id_rsa_y0usaf
      '';

      ###########################################################################
      # SSH Agent Service
      ###########################################################################
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

      ###########################################################################
      # Shell Integration
      ###########################################################################
      file.home.".zshenv".text = lib.mkAfter ''
        # SSH Agent Integration
        export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent"
      '';
    };
  };
}

###############################################################################
# SSH Server Configuration Module
# Secure OpenSSH server setup for remote system access:
# - Key-based authentication
# - Secure defaults
# - Customizable settings
# - Firewall rules
###############################################################################
{
  config,
  lib,
  pkgs,
  hostSystem,
  hostHome,
  ...
}: let
  cfg = hostSystem.cfg.core.ssh;
in {
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # OpenSSH Server Configuration
    # Secure remote access to the system
    ###########################################################################
    services.openssh = {
      enable = true;
      settings = {
        # Security Settings
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        KbdInteractiveAuthentication = false;
        
        # Hardening
        X11Forwarding = false;
        UseDns = false;
        
        # Connection settings
        TCPKeepAlive = true;
        ClientAliveInterval = 60;
        ClientAliveCountMax = 5;
      };
      
      # Add extraConfig here if needed for advanced settings
      extraConfig = '''';
      
      # OpenSSH server port (default: 22)
      ports = [22];
      
      # Use system OpenSSH package
      package = pkgs.openssh;
    };

    ###########################################################################
    # Firewall Configuration for SSH
    # Allow SSH connections through the firewall
    ###########################################################################
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [22]; # Match the SSH port(s) configured above
    };
  };
}
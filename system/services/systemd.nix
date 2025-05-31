###############################################################################
# Systemd Service Configuration
# Enhanced systemd configuration for debugging shutdown issues:
# - Debug logging for shutdown tracking
# - Verbose service status reporting
# - Reasonable timeout configurations
###############################################################################
{
  pkgs,
  ...
}: {
  config = {
    ###########################################################################
    # Systemd Configuration
    # Enhanced logging and debugging for shutdown issues
    ###########################################################################

    # Enable debug logging for systemd to track shutdown issues
    systemd.extraConfig = ''
      LogLevel=debug
      LogTarget=journal
      DefaultTimeoutStopSec=30s
      DefaultTimeoutStartSec=30s
    '';

    # Add useful systemd analysis tools to system packages
    environment.systemPackages = with pkgs; [
      systemd # For systemd-analyze and other systemd tools
      (writeShellScriptBin "shutdown-tracker" (builtins.readFile ../../lib/scripts/shutdown-tracker.sh))
    ];

    # Configure journald for better logging retention
    services.journald.extraConfig = ''
      SystemMaxUse=500M
      SystemKeepFree=1G
      SystemMaxFileSize=50M
      MaxRetentionSec=1month
    '';

    # Create a simple script to analyze shutdown issues
    environment.shellAliases = {
      shutdown-debug = "journalctl -b -1 --no-pager | grep -E '(Stopping|Failed|timeout|kill)'";
      shutdown-analyze = "systemd-analyze blame && echo '--- Critical Chain ---' && systemd-analyze critical-chain";
      shutdown-last = "journalctl -b -1 -u '*.service' --no-pager | tail -50";
    };
  };
}

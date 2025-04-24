###############################################################################
# Security Modules Configuration
# This file imports all security-related modules:
# - Real-time kit for audio/video tasks
# - PolicyKit for fine-grained permission control
# - Sudo configurations
###############################################################################
{
  imports = [
    ./rtkit.nix
    ./polkit.nix
    ./sudo.nix
  ];
}
###############################################################################
# CA Certificates Configuration
# Ensures proper SSL/TLS certificate validation for system and user tools
###############################################################################
{pkgs, ...}: {
  ###########################################################################
  # CA Certificates
  ###########################################################################
  security.ca-derivations = {
    enable = true;
  };

  # System-wide CA certificates
  security.pki.certificates = [];

  # Ensure ca-certificates package is available system-wide
  environment.systemPackages = with pkgs; [
    cacert
  ];

  # Environment variables for SSL/TLS
  environment.variables = {
    SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
  };
}
###############################################################################
# Configuration Merge Module
# Merges host-specific home configuration
###############################################################################
{hostHome ? {}, ...}: {
  ###########################################################################
  # Home Configuration Merge
  ###########################################################################

  # Extract the appropriate configuration sections from hostHome
  cfg = hostHome.cfg or {};
}

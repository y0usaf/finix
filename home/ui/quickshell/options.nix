###############################################################################
# Quickshell Module Options
# Module option definitions for quickshell configuration
###############################################################################
{lib, ...}: {
  options.home.ui.quickshell = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Quickshell desktop shell";
    };
  };
}

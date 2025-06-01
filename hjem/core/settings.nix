#═══════════════════════════ 🔧 HJEM GLOBAL SETTINGS MODULE 🔧 ═══════════════════════════#
{
  config,
  lib,
  ...
}: {
  # Define global Hjem settings
  options.cfg.hjem = {
    clobberFiles = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to clobber (overwrite) existing files globally.";
    };
    
    # Add other global Hjem options here as needed
  };

  # Apply the global settings to the actual Hjem configuration
  config.clobberFiles = config.cfg.hjem.clobberFiles;
}
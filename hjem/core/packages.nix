###############################################################################
# Packages Collector Module for Hjem
# Collects packages from individual modules and adds them to the top-level
###############################################################################
{
  config,
  lib,
  ...
}: {
  # Define the option for collecting packages from modules
  options.packageCollector = {
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Packages to collect from all modules";
    };
  };

  # Add the collected packages to the top-level packages attribute
  config.packages = config.packageCollector.packages;
}

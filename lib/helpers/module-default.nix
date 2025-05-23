###############################################################################
# Shared Module Default Template
# Reusable template for module default.nix files
# Usage: import ../../../lib/helpers/module-default.nix {
#   inherit lib;
#   description = "Module description";
#   features = ["feature1" "feature2"];
# }
###############################################################################
{
  lib,
  description ? "Module Configuration",
  features ? [],
  excludeFiles ? [],
}: let
  # Import all modules in current directory, excluding specified files
  allImports = (import ./import-modules.nix {inherit lib;}) ./.;
  filteredImports =
    builtins.filter
    (path: !builtins.any (exclude: lib.hasSuffix exclude (toString path)) excludeFiles)
    allImports;

  featureList =
    if features == []
    then ""
    else "\n# Features:\n" + (lib.concatMapStringsSep "\n" (f: "# - ${f}") features);
in {
  imports = filteredImports;

  # Add module metadata as comments (for documentation)
  _module.args._moduleInfo = {
    inherit description features;
    comment = ''
      ###############################################################################
      # ${description}${featureList}
      ###############################################################################
    '';
  };
}

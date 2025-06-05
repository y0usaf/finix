# Test file to debug file registry
{
  config,
  pkgs,
  lib,
  ...
}: let
  registry = import ./lib/helpers/file-registry.nix {inherit lib;};
in {
  imports = [
    # Test just the file registry
    {options = registry.mkFileRegistryOptions;}
  ];

  config = {
    # Test declarations
    fileRegistry.declare = {
      testfile = ".testfile";
    };

    # Test content
    fileRegistry.content = {
      testfile.section1 = "# Section 1\necho test1";
      testfile.section2 = "# Section 2\necho test2";
    };
  };
}

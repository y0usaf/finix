let
  lib = import <nixpkgs/lib>;
  generators = import ./lib/generators/toHyprconf.nix lib;
  
  # Test configuration with bezier at top level and animations as separate section
  testConfig = {
    "$test" = "value";
    bezier = [
      "test-bezier,0,0,0,1"
    ];
    animations = {
      enabled = 1;
      animation = [
        "windows,1,2,test-bezier,popin"
      ];
    };
    general = {
      gaps_in = 5;
    };
    bind = [
      "$mod, Q, killactive"
    ];
  };
  
  result = generators.toHyprconf {
    attrs = testConfig;
    importantPrefixes = ["$"];
  };
in
  builtins.trace "Test result with bezier fix:" result
let
  lib = import <nixpkgs/lib>;
  
  # Simulate the core config
  coreConfig = {
    bezier = [
      "in-out,.65,-0.01,0,.95"
      "woa,0,0,0,1"
    ];
    animations = {
      enabled = 0;
      animation = [
        "windows,1,2,woa,popin"
        "border,1,10,default"
        "fade,1,10,default"
        "workspaces,1,5,in-out,slide"
      ];
    };
  };
  
  # Test the toHyprconf generator
  generators = import ./lib/generators/toHyprconf.nix lib;
  
  result = generators.toHyprconf {
    attrs = coreConfig;
    importantPrefixes = ["$"];
  };
in
  builtins.trace "Generated config:" result
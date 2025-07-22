{hostsDir ? ../../hosts}: {
  mkNixosModule = {
    inputs,
    hostname,
  }: {
    config,
    pkgs,
    ...
  }: let
    hostConfig = import (hostsDir + "/${hostname}/default.nix") {inherit pkgs inputs;};
    homeConfig = hostConfig.home or {};
  in {
    imports = [
      (import (inputs.nix-maid.outPath + "/src/nixos") {
        smfh = null; # We'll handle smfh differently
      })
    ];
    config = {
      home = homeConfig;
      maid.linker = (import inputs.nix-maid.outPath {inherit (pkgs) system;}).packages.${pkgs.system}.smfh;
      users.users.y0usaf.maid = {
        packages = [];
      };
    };
  };
}

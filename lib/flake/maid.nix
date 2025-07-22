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
      inputs.nix-maid.nixosModules.default
    ];
    config = {
      home = homeConfig;
      maid.linker = inputs.nix-maid.packages.${pkgs.system}.smfh;
      users.users.y0usaf.maid = {
        packages = [];
      };
    };
  };
}

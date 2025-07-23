{hostsDir ? ../../hosts}: {
  mkNixosModule = {
    inputs,
    hostname,
    users,
    userConfigs,
  }: {
    config,
    pkgs,
    lib,
    ...
  }: {
    imports = [
      (import (inputs.nix-maid.outPath + "/src/nixos") {
        smfh = null; # We'll handle smfh differently
      })
    ];
    config = {
      # Merge all user home configs (excluding system config)
      home = lib.mkMerge (lib.mapAttrsToList (
          username: userConfig:
            builtins.removeAttrs userConfig ["system"]
        )
        userConfigs);
      # maid.linker = (import inputs.nix-maid.outPath {inherit (pkgs) system;}).packages.${pkgs.system}.smfh; # TODO: Fix maid linker
      users.users = lib.genAttrs users (username: {
        maid = {
          packages = [];
        };
      });
    };
  };
}

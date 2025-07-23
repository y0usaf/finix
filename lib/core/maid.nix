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

    options = {
      # Define any additional options here if needed
    };

    config = {
      # Use proper NixOS module merging instead of manual attribute manipulation
      home = lib.mkMerge (
        lib.mapAttrsToList (
          username: userConfig:
          # Remove system-specific config that doesn't belong in home
            lib.filterAttrs (name: _: name != "system") userConfig
        )
        userConfigs
      );

      # Configure maid for each user
      users.users = lib.genAttrs users (username: {
        maid = {
          packages = [];
        };
      });

      # TODO: Fix maid linker when ready
      # maid.linker = (import inputs.nix-maid.outPath {inherit (pkgs) system;}).packages.${pkgs.system}.smfh;
    };
  };
}

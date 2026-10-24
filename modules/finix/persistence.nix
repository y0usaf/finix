{
  config,
  lib,
  ...
}: {
  options.finix.persistence.allowlist = lib.mkOption {
    description = "Host persistence policy consumed by native Finix mount modules.";
    default = {};
    type = lib.types.submodule {
      options = {
        directories = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
        };
        users = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule {
            options = {
              directories = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [];
              };
              files = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [];
              };
            };
          });
          default = {};
        };
      };
    };
  };

  config = {
    fileSystems = lib.genAttrs (builtins.filter (dir: !lib.hasPrefix "/etc/" dir && dir != "/root")
      config.finix.persistence.allowlist.directories) (dir: {
      device = "/persist${dir}";
      fsType = "btrfs";
      options = ["bind"];
      neededForBoot = true;
    });
  };
}

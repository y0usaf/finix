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
              directorySources = lib.mkOption {
                description = "Programs persist-user-binds runs at boot, as root, that print more directories to persist, relative to home, one per line, read from state that itself persists (omp-bot's roster). An entry that is absolute, holds `.` or `..`, or resolves outside home is skipped, and a failing entry never fails the boot.";
                type = lib.types.listOf lib.types.path;
                default = [];
              };
            };
          });
          default = {};
        };
      };
    };
  };

  config.fileSystems = lib.genAttrs (builtins.filter (dir: !lib.hasPrefix "/etc/" dir && dir != "/root")
    config.finix.persistence.allowlist.directories) (dir: {
    device = "/persist${dir}";
    fsType = "btrfs";
    options = ["bind"];
    neededForBoot = true;
  });
}

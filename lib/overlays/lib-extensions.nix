# Extended lib overlay with helper functions
_final: prev: {
  lib = prev.lib.extend (_libfinal: libprev: let
    # Import generators
    generators = import ../generators {lib = libprev;};
  in {
    # Add generators to lib
    generators =
      libprev.generators
      // {
        # Hyprland generators (only the used ones)
        inherit (generators) toHyprconf pluginsToHyprconf;
      };

    # Directory and module importers
    importDirs = dir: let
      dirs = libprev.filterAttrs (n: v: v == "directory" && n != ".git") (builtins.readDir dir);
      dirPaths = libprev.mapAttrsToList (name: _: dir + "/${name}/default.nix") dirs;
    in
      libprev.filter (path: builtins.pathExists path) dirPaths;

    importModules = dir: let
      files = libprev.filterAttrs (n: v: v == "regular" && libprev.hasSuffix ".nix" n && n != "default.nix") (builtins.readDir dir);
    in
      map (name: dir + "/${name}") (builtins.attrNames files);

    # Type shortcuts
    t = libprev.types;
    mkOpt = type: description: libprev.mkOption {inherit type description;};
    mkBool = libprev.types.bool;
    mkStr = libprev.types.str;
    mkOptDef = type: default: description: libprev.mkOption {inherit type default description;};

    # User configuration helpers
    mkUserHjemConfig = username: userConfig: {
      hjem.users.${username} = userConfig;
    };

    # Package option helper
    mkPackageOption = description:
      libprev.mkOption {
        type = libprev.types.package;
        inherit description;
      };

    # Service module pattern
    mkServiceModule = {
      name,
      description ? "Enable ${name}",
      extraOptions ? {},
    }:
      {
        enable = libprev.mkEnableOption description;
        package = libprev.mkOption {
          type = libprev.types.package;
          description = "Package for ${name}";
        };
      }
      // extraOptions;

    # Common module types
    defaultAppModule = libprev.types.submodule {
      options = {
        command = libprev.mkOption {
          type = libprev.types.str;
          description = "Command to execute the application.";
        };
      };
    };

    dirModule = libprev.types.submodule {
      options = {
        path = libprev.mkOption {
          type = libprev.types.str;
          description = "Absolute path to the directory";
        };
        create = libprev.mkOption {
          type = libprev.types.bool;
          default = true;
          description = "Whether to create the directory if it doesn't exist";
        };
      };
    };
  });
}

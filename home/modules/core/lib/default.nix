{lib, ...}: {
  # Type definitions for options
  t = lib.types;
  mkOpt = type: description: lib.mkOption {inherit type description;};
  mkBool = lib.types.bool;
  mkStr = lib.types.str;
  mkOptDef = type: default: description: lib.mkOption {inherit type default description;};

  # Define common structure for default application configuration
  defaultAppModule = lib.types.submodule {
    options = {
      # command: Specifies the command to run the application.
      command = lib.mkOption {
        type = lib.types.str;
        description = "Command to execute the application.";
      };
    };
  };

  # Define common structure for directory configuration
  dirModule = lib.types.submodule {
    options = {
      # path: Defines the absolute path to the directory.
      path = lib.mkOption {
        type = lib.types.str;
        description = "Absolute path to the directory";
      };
      # create: Determines if the directory should be created automatically if not found.
      create = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to create the directory if it doesn't exist";
      };
    };
  };
}
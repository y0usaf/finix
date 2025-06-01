###############################################################################
# Hjem Configuration Utilities
# Functions for generating Hjem user configurations
###############################################################################
{
  lib,
  pkgs,
  helpers,
  ...
}: let
  shared = import ./shared.nix {inherit lib pkgs helpers;};

  # Helper function to generate module-like abstractions for Hjem
  mkHjemModule = {
    name,
    # Function that returns a set of files to create/manage
    filesFunc,
    # Optional default config
    defaults ? {},
  }: config: let
    # Allow enable=false to disable the entire module
    enabled = config.enable or true;
    # Merge defaults with user config
    finalConfig = defaults // (removeAttrs config ["enable"]);
  in
    if enabled
    then filesFunc finalConfig
    else {};

  # Collection of module-like abstractions for Hjem
  modules = {
    # Example: Git configuration
    git = mkHjemModule {
      name = "git";
      defaults = {
        userName = "";
        userEmail = "";
        aliases = {};
      };
      filesFunc = cfg: {
        ".gitconfig".text = ''
          [user]
            name = ${cfg.userName}
            email = ${cfg.userEmail}
          [core]
            editor = ${cfg.editor or "vim"}
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: ''
              [alias]
                ${name} = ${value}
            '')
            cfg.aliases)}
        '';
      };
    };
  };

  # Process a Hjem configuration that follows HM-like module structure
  # e.g., { programs.git = { font = "Fira Code"; }; }
  # -> { ".gitconfig" = { text = "..."; }; }
  processHjemConfig = config: let
    # Process programs section
    programFiles =
      if config ? programs
      then
        lib.foldl (
          acc: name:
            if config.programs ? ${name} && modules ? ${name}
            then acc // modules.${name} config.programs.${name}
            else acc
        ) {} (lib.attrNames config.programs)
      else {};

    # Process direct files
    directFiles = config.files or {};

    # Merge all file definitions
    allFiles = directFiles // programFiles;
  in {
    packages = config.packages or [];
    environment = config.environment or {};
    clobberFiles = config.clobberFiles or false;
    files = allFiles;
  };
in {
  # Export utilities
  inherit modules mkHjemModule processHjemConfig;
}

inputs: let
  inherit (inputs.nixpkgs) lib;
  system = "x86_64-linux";
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [
      (final: prev: {
        lib = prev.lib.extend (libfinal: libprev: {
          importDirs = dir: let
            dirs =
              libprev.filterAttrs (n: v: v == "directory" && n != ".git")
              (builtins.readDir dir);
            dirPaths = libprev.mapAttrsToList (name: _: dir + "/${name}/default.nix") dirs;
          in
            libprev.filter (path: builtins.pathExists path) dirPaths;
          importModules = dir: let
            files =
              libprev.filterAttrs (n: v: v == "regular" && libprev.hasSuffix ".nix" n && n != "default.nix")
              (builtins.readDir dir);
          in
            map (name: dir + "/${name}") (builtins.attrNames files);
          t = libprev.types;
          mkOpt = type: description: libprev.mkOption {inherit type description;};
          mkBool = libprev.types.bool;
          mkStr = libprev.types.str;
          mkOptDef = type: default: description: libprev.mkOption {inherit type default description;};
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
      })
      inputs.neovim-nightly-overlay.overlays.default
      (_final: _prev: {
        fastFonts = inputs.fast-fonts.packages.${system}.default;
      })
    ];
    config.allowUnfree = true;
    config.cudaSupport = true;
  };
  hostUtils = import ../default.nix {
    inherit (pkgs) lib;
    inherit pkgs;
  };
  commonSpecialArgs = {
    inherit inputs;
    inherit (inputs) disko fast-fonts nix-minecraft;
  };
in {
  formatter.${system} = pkgs.alejandra;
  nixosConfigurations = hostUtils.mkNixosConfigurations {
    inherit inputs system commonSpecialArgs;
  };
}

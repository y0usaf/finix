{
  lib,
  pkgs,
  sources,
  userConfigs,
  hostsDir ? ../hosts,
}: {
  mkNixosConfigurations = {
    inputs,
    system,
    commonSpecialArgs,
  }: let
    hostNames = ["y0usaf-desktop"];
    maidIntegration = import ./flake/maid.nix {inherit hostsDir;};
  in
    builtins.listToAttrs (map
      (hostname: let
        hostConfig = import (hostsDir + "/${hostname}/default.nix") {
          inherit pkgs inputs;
        };
        # Get users from host config
        users = hostConfig.users;
        # Create user configs for all users
        userConfigs' = lib.genAttrs users (username: userConfigs.${username});
      in {
        name = hostname;
        value = import (sources.nixpkgs + "/nixos") {
          inherit system;
          configuration = {
            imports = [
              ({config, ...}: {
                imports = hostConfig.imports;
                hostSystem = {
                  users = hostConfig.users;
                  hostname = hostConfig.hostname;
                  homeDirectory = hostConfig.homeDirectory;
                  stateVersion = hostConfig.stateVersion;
                  timezone = hostConfig.timezone;
                  profile = hostConfig.profile or "default";
                  hardware = hostConfig.hardware or {};
                  services = hostConfig.services or {};
                };
                # Configure nixpkgs to use our overlays
                nixpkgs.overlays = let
                  mkOverlays = sources: [
                    # Extended lib overlay with helper functions
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
                    # Neovim nightly overlay
                    (import sources.neovim-nightly-overlay)
                    # Fast fonts overlay
                    (final: _prev: {
                      fastFonts = final.stdenvNoCC.mkDerivation {
                        pname = "fast-fonts";
                        version = "1.0.0";
                        src = sources.Fast-Font;

                        installPhase = ''
                          mkdir -p $out/share/fonts/truetype
                          install -m444 -Dt $out/share/fonts/truetype *.ttf
                          mkdir -p $out/share/doc/fast-fonts
                          if [ -f LICENSE ]; then
                            install -m444 -Dt $out/share/doc/fast-fonts LICENSE
                          fi
                          if [ -f README.md ]; then
                            install -m444 -Dt $out/share/doc/fast-fonts README.md
                          fi
                        '';

                        meta = with final.lib; {
                          description = "Fast Font Collection - TTF fonts";
                          longDescription = "Fast Font Collection provides optimized monospace and sans-serif fonts";
                          homepage = "https://github.com/y0usaf/Fast-Font";
                          platforms = platforms.all;
                          license = licenses.mit;
                        };
                      };
                    })
                  ];
                in
                  mkOverlays sources;
                nixpkgs.config.allowUnfree = true;
                nixpkgs.config.cudaSupport = true;
              })
              (maidIntegration.mkNixosModule {
                inherit inputs hostname users;
                userConfigs = userConfigs';
              })
              ../home
              # (inputs.chaotic.outPath + "/modules/nixos/default.nix") # TODO: Fix chaotic integration
            ];
            _module.args =
              commonSpecialArgs
              // {
                inherit hostname hostsDir users;
                lib = lib; # Use the extended lib passed to npins-system.nix
                hostConfig = hostConfig;
                userConfigs = userConfigs';
                hostSystem = hostConfig;
              };
          };
        };
      })
      hostNames);
}

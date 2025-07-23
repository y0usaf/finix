let
  # Import npins sources
  sources = import ./npins;

  system = "x86_64-linux";

  # Import nixpkgs first to get lib with nixosSystem
  nixpkgs = import sources.nixpkgs {inherit system;};

  # Consolidated overlays function
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

  # Import nixpkgs with overlays for pkgs
  pkgs = import sources.nixpkgs {
    inherit system;
    overlays = mkOverlays sources;
    config.allowUnfree = true;
    config.cudaSupport = true;
  };

  # Import user configurations
  userConfigs = {
    y0usaf = import ./users/y0usaf/default.nix {
      pkgs = pkgs;
      inputs = inputs;
    };
    guest = import ./users/guest/default.nix {
      pkgs = pkgs;
      inputs = inputs;
    };
  };

  # Import NixOS configuration builder
  nixosBuilder = import ./lib/builders/nixos.nix {
    inherit sources pkgs userConfigs;
    lib = pkgs.lib;
  };

  # Create inputs-like structure from npins sources
  inputs = {
    nixpkgs =
      nixpkgs
      // {
        lib = pkgs.lib;
        # Pass the source path for modules that need to import nixpkgs
        outPath = sources.nixpkgs;
      };
    nix-maid = {outPath = sources.nix-maid;};
    alejandra = {outPath = sources.alejandra;};
    disko = {outPath = sources.disko;};
    hyprland = {outPath = sources.Hyprland;};
    hy3 = {outPath = sources.hy3;};
    deepin-dark-hyprcursor = {outPath = sources.Deepin-Dark-hyprcursor;};
    deepin-dark-xcursor = {outPath = sources.Deepin-Dark-xcursor;};
    fast-fonts = {outPath = sources.Fast-Font;};
    hyprpaper = {outPath = sources.hyprpaper;};
    obs-image-reaction = {outPath = sources.obs-image-reaction;};
    chaotic = {outPath = sources.nyx;};
    nix-minecraft = {outPath = sources.nix-minecraft;};
    mnw = {outPath = sources.mnw;};
    neovim-nightly-overlay = {outPath = sources.neovim-nightly-overlay;};
  };

  # Use npins system utilities directly

  # Common special args for all hosts
  commonSpecialArgs = {
    inherit inputs;
    inherit (inputs) disko fast-fonts nix-minecraft;
  };
in {
  # Formatter
  formatter.${system} = pkgs.alejandra;

  # NixOS configurations
  nixosConfigurations = nixosBuilder.mkNixosConfigurations {
    inherit inputs system commonSpecialArgs;
  };
}

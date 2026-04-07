{inputs}: let
  system = "x86_64-linux";
  inherit (inputs.nixpkgs) lib;
  recursivelyImport = import ./recursivelyImport.nix {inherit lib;};

  baseNixpkgsConfig = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "qtwebengine-5.15.19"
      "electron-38.8.4"
    ];
    allowInsecurePredicate = pkg:
      lib.hasPrefix "librewolf" (pkg.pname or "")
      || lib.hasPrefix "electron" (pkg.pname or "");
  };

  baseOverlays = [
    inputs.claude-code-nix.overlays.default
  ];

  desktopOverlays =
    baseOverlays
    ++ [
      inputs.gpui-shell.overlays.default
      inputs.agent-harness.overlays.default
      # Fix obs-vertical-canvas Qt6GuiPrivate cmake detection
      (_: prev: let
        prevObsPlugins = prev.obs-studio-plugins;
      in {
        obs-studio-plugins =
          prevObsPlugins
          // {
            obs-vertical-canvas = prevObsPlugins.obs-vertical-canvas.overrideAttrs (old: {
              postPatch =
                (old.postPatch or "")
                + ''
                  sed -i '/find_qt(COMPONENTS Widgets COMPONENTS_LINUX Gui)/a find_package(Qt6 REQUIRED COMPONENTS GuiPrivate)' CMakeLists.txt
                '';
            });
          };
      })
    ];

  pkgsForDesktop = import inputs.nixpkgs {
    inherit system;
    config = baseNixpkgsConfig // {cudaSupport = true;};
    overlays = desktopOverlays;
  };

  pkgsForServer = import inputs.nixpkgs {
    inherit system;
    config = baseNixpkgsConfig // {cudaSupport = false;};
    overlays = baseOverlays;
  };

  sharedModules = [
    (inputs.disko + "/module.nix")
    ({...}: {
      imports = [
        inputs.bayt.nixosModules.default
      ];
      config.bayt = {
        clobberByDefault = true;
        users = {};
      };
    })
    inputs.tweakcc.nixosModules.default
    inputs.mango.nixosModules.mango
    inputs.impermanence.nixosModules.impermanence
    inputs.patchix.nixosModules.default
    inputs.nvtune.nixosModules.default
  ];

  moduleDomains = {
    core = [./modules/core];
    desktop = [./modules/desktop];
    shell = [./modules/shell];
    tools = [./modules/tools];
    user-services = [./modules/user-services];
    dev = [./modules/dev];
    gaming = [./modules/gaming];
  };

  mkHost = {
    hostDir,
    profileDir,
    domains,
    pkgs,
  }:
    lib.nixosSystem {
      inherit system;
      specialArgs = {
        flakeInputs = inputs;
        inherit (inputs) disko;
        genLib = import ./lib/generators {
          inherit (pkgs) lib;
          inherit pkgs;
        };
      };
      modules = recursivelyImport (
        sharedModules
        ++ [{nixpkgs.pkgs = pkgs;}]
        ++ lib.concatMap (domain: moduleDomains."${domain}") domains
        ++ [
          profileDir
          hostDir
        ]
      );
    };
in {
  y0usaf-desktop = mkHost {
    hostDir = ./hosts/y0usaf-desktop;
    profileDir = ./modules/profiles/y0usaf;
    pkgs = pkgsForDesktop;
    domains = [
      "core"
      "desktop"
      "shell"
      "tools"
      "user-services"
      "dev"
      "gaming"
    ];
  };

  y0usaf-laptop = mkHost {
    hostDir = ./hosts/y0usaf-laptop;
    profileDir = ./modules/profiles/y0usaf;
    pkgs = pkgsForDesktop;
    domains = [
      "core"
      "desktop"
      "shell"
      "tools"
      "user-services"
      "dev"
      "gaming"
    ];
  };

  y0usaf-framework = mkHost {
    hostDir = ./hosts/y0usaf-framework;
    profileDir = ./modules/profiles/y0usaf-dev;
    pkgs = pkgsForDesktop;
    domains = [
      "core"
      "desktop"
      "shell"
      "tools"
      "user-services"
      "dev"
      "gaming"
    ];
  };

  y0usaf-server = mkHost {
    hostDir = ./hosts/y0usaf-server;
    profileDir = ./modules/profiles/server;
    pkgs = pkgsForServer;
    domains = [
      "core"
      "shell"
      "tools"
      "user-services"
      "dev"
    ];
  };
}

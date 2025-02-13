#===============================================================================
#                        💻 VSCode Configuration 💻
#===============================================================================
# 🔄 VSCode/Cursor overlay
# 🛠️ Package configuration
#===============================================================================
{
  config,
  pkgs,
  lib,
  profile,
  ...
}: let
  # Add Cursor to the VSCode module's known packages
  configDir = {
    "vscode" = "Code";
    "code-cursor" = "Cursor";
  };
in {
  nixpkgs.overlays = [
    (final: prev: {
      code-cursor = prev.vscode.overrideAttrs (oldAttrs: {
        pname = "code-cursor";
        inherit (prev.vscode) version;
        postInstall = ''
          ${oldAttrs.postInstall or ""}
          # Modify the desktop entry
          substituteInPlace $out/share/applications/code.desktop \
            --replace "Code" "Cursor" \
            --replace "com.visualstudio.code" "com.cursor.code"
          # Create new desktop entry file
          mv $out/share/applications/code.desktop $out/share/applications/cursor.desktop
        '';
      });
    })
  ];

  # Add our configDir mapping to the module
  disabledModules = [ "programs/vscode.nix" ];
  imports = [
    (
      { config, lib, pkgs, ... }:
      {
        options.programs.vscode = {
          enable = lib.mkEnableOption "Visual Studio Code";

          package = lib.mkOption {
            type = lib.types.package;
            default = pkgs.vscode;
            description = "Which package to use for VS Code.";
          };

          mutableExtensionsDir = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Directory for mutable extensions.";
          };

          userSettings = lib.mkOption {
            type = lib.types.attrs;
            default = {};
            description = "User settings for VS Code.";
          };

          extensions = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [];
            description = "VS Code extensions to install.";
          };

          configDir = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = configDir;
            description = "Mapping of package names to their config directories";
          };
        };

        config = lib.mkIf config.programs.vscode.enable {
          home.packages = [ config.programs.vscode.package ] 
            ++ config.programs.vscode.extensions;
        };
      }
    )
  ];

  # VSCode/Cursor configuration
  programs.vscode = {
    enable = true;
    package = pkgs.code-cursor;
    mutableExtensionsDir = "~/.cursor/extensions";

    # Your current extensions
    extensions = with pkgs.vscode-extensions; [
      # Core extensions
      vscodevim.vim  # asvetliakov.vscode-neovim
      bbenoist.nix
      charliermarsh.ruff
      davidanson.vscode-markdownlint
      esbenp.prettier-vscode
      ms-python.python
      ms-python.vscode-pylance
      
      # Additional extensions (some might need to be added to nixpkgs or installed manually)
      # dvirtz.parquet-viewer
      # ms-toolsai.jupyter
      # ms-toolsai.jupyter-renderers
      # ms-toolsai.vscode-jupyter-cell-tags
      # ms-toolsai.vscode-jupyter-slideshow
      # nimda.deepdark-material
      # tamasfe.even-better-toml
    ];

    userSettings = {
      "window.zoomLevel" = 2;
      "window.zoomPerWindow" = false;
      "extensions.experimental.affinity" = {
        "asvetliakov.vscode-neovim" = 1;
      };
      "explorer.confirmDelete" = false;
      "cursor.cpp.disabledLanguages" = [
        "plaintext"
        "nix"
      ];
      "cursor-retrieval.canAttemptGithubLogin" = false;
      "editor.fontFamily" = "IosevkaTermSlab Nerd Font Mono";
      "roo-cline.allowedCommands" = [
        "npm test"
        "npm install"
        "tsc"
        "git log"
        "git diff"
        "git show"
        "nh os test"
        "nh os switch"
        "rm"
        "touch"
      ];
      "application.shellEnvironmentResolutionTimeout" = 1;
      "window.customTitleBarVisibility" = "auto";
      "workbench.activityBar.location" = "hidden";
      "window.commandCenter" = false;
      "workbench.colorTheme" = "Deepdark Material Theme | Full Black Version";
      "explorer.confirmDragAndDrop" = false;
    };
  };

  # Create symlinks for additional Cursor-specific paths
  home.file = {
    ".cursor/argv.json".text = builtins.toJSON {
      "enable-crash-reporter" = true;
      "crash-reporter-id" = "f31feac7-e741-4534-af0f-54c7d6b120d9";
      "password-store" = "basic";
    };
  };
} 
{
  config,
  pkgs,
  lib,
  profile,
  ...
}: let
  # Helper function to determine if development feature is enabled
  isDevelopment = builtins.elem "development" profile.features;
  # Get the main font name from profile
  mainFontName = builtins.elemAt (builtins.elemAt profile.fonts.main 0) 1;
in {
  config = lib.mkIf isDevelopment {
    # Override the default VSCode configuration to work with Cursor
    programs.vscode = {
      enable = true;
      package = profile.defaultIde.package;  # Use the IDE package from profile
      mutableExtensionsDir = false;
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;
      # Directly use Cursor's config directory
      configDir = "Cursor";

      userSettings = {
        # Window settings
        "window.zoomLevel" = 2;
        "window.zoomPerWindow" = false;
        "window.commandCenter" = false;
        "window.customTitleBarVisibility" = "auto";
        
        # Editor settings using profile fonts and sizes
        "editor.fontFamily" = mainFontName;
        "editor.fontSize" = profile.baseFontSize;
        "explorer.confirmDelete" = false;
        
        # Workbench settings
        "workbench.activityBar.location" = "hidden";
        
        # Cursor-specific settings
        "cursor.cpp.disabledLanguages" = [
          "plaintext"
          "nix"
        ];
        "cursor-retrieval.canAttemptGithubLogin" = false;
        
        # Neovim integration
        "extensions.experimental.affinity" = {
          "asvetliakov.vscode-neovim" = 1
        };
        
        # Shell settings
        "application.shellEnvironmentResolutionTimeout" = 1;
        
        # Roo-cline allowed commands
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
      };

      extensions = with pkgs.vscode-extensions; [
        # Your current extensions
        ms-python.python
        ms-python.vscode-pylance
        bbenoist.nix
        esbenp.prettier-vscode
        
        # Additional useful extensions that match your setup
        charliermarsh.ruff
        davidanson.vscode-markdownlint
        tamasfe.even-better-toml
      ] ++ (with pkgs.vscode-marketplace; [
        # Extensions not in nixpkgs
        {
          name = "vscode-neovim";
          publisher = "asvetliakov";
          version = "1.18.15";
        }
        {
          name = "deepdark-material";
          publisher = "nimda";
          version = "3.3.1";
        }
        {
          name = "roo-cline";
          publisher = "rooveterinaryinc";
          version = "3.3.11";
        }
      ]);
    };
  };
} 
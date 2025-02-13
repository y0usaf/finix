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
}: {
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

  # VSCode/Cursor configuration
  programs.vscode = {
    enable = true;
    package = pkgs.code-cursor;
    # Override the config locations to match Cursor's paths
    mutableExtensionsDir = "~/.cursor/extensions";
    userSettings = {
      # Your settings here
    };
    # Override the config target directory
    configDir = "~/.config/Cursor";
  };

  # Create symlinks for additional Cursor-specific paths
  home.file = {
    ".cursor/argv.json".source = config.lib.file.mkOutOfStoreSymlink 
      "${config.home.homeDirectory}/.config/Cursor/argv.json";
  };
} 
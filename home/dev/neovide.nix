###############################################################################
# Neovide Configuration for Development
# Modern Neovim GUI with smooth animations - organized under dev module
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.dev.nvim;
  inherit (config.shared) username;
  
  # Get font configuration from appearance module
  mainFontName = (builtins.elemAt config.home.core.appearance.fonts.main 0).name;
  fontSize = toString (config.home.core.appearance.baseFontSize * 1.0);
in {
  ###########################################################################
  # Neovide-specific Configuration (when enabled via nvim.neovide option)
  ###########################################################################
  config = lib.mkIf (cfg.enable && cfg.neovide) {
    users.users.${username}.maid = {
      packages = with pkgs; [
        neovide
      ];

      # Neovide-specific dotfiles
      file.home = {
        ".config/neovide/config.toml".text = ''
          # Font configuration
          [font]
          normal = ["${mainFontName}"]
          size = ${fontSize}.0
          
          # Basic settings
          vsync = true
          remember_window_size = true
        '';
        
        # Desktop entry for Neovide
        ".local/share/applications/neovide-dev.desktop".text = ''
          [Desktop Entry]
          Type=Application
          Name=Neovide (Dev)
          Comment=Enhanced Neovim GUI for Development
          Exec=${pkgs.neovide}/bin/neovide %F
          Icon=neovide
          Terminal=false
          Categories=Development;TextEditor;
          StartupWMClass=neovide
          MimeType=text/plain;text/x-makefile;text/x-c++hdr;text/x-c++src;text/x-chdr;text/x-csrc;text/x-java;text/x-moc;text/x-pascal;text/x-tcl;text/x-tex;application/x-shellscript;text/x-c;text/x-c++;text/x-python;text/x-rust;text/x-nix;
          StartupNotify=true
          Keywords=neovim;editor;development;
        '';
      };
    };
    
    # Environment variables for Neovide
    home.sessionVariables = {
      NEOVIDE_MULTIGRID = "1";
      NEOVIDE_FRAME = "full";
    };
  };
}
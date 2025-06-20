###############################################################################
# Neovide Configuration
# Modern Neovim GUI with smooth animations and native performance (nix-maid)
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.ui.neovide;
  inherit (config.shared) username;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.ui.neovide = {
    enable = lib.mkEnableOption "Neovide GUI for Neovim";
    
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.neovide;
      description = "The Neovide package to use";
    };
    
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Neovide configuration options";
    };
  };

  ###########################################################################
  # Module Configuration (nix-maid)
  ###########################################################################
  config = lib.mkIf cfg.enable {
    users.users.${username}.maid = {
      packages = [ cfg.package ];
      
      file.home = {
        # Neovide configuration file
        ".config/neovide/config.toml".text = lib.generators.toTOML {} (lib.mkMerge [
          {
            # Performance settings
            idle = true;
            maximized = false;
            
            # Font configuration
            font = {
              normal = ["JetBrainsMono Nerd Font"];
              size = 12.0;
              hinting = "full";
              edging = "antialias";
            };
            
            # Theme and appearance
            theme = "auto";
            transparency = 0.95;
            blur = true;
            
            # Animation settings
            cursor = {
              animation_length = 0.05;
              animation_trail_size = 0.8;
              antialiasing = true;
              animate_in_insert_mode = true;
              animate_command_line = true;
              vfx_mode = "railgun";
              vfx_opacity = 200.0;
              vfx_particle_density = 10.0;
              vfx_particle_lifetime = 1.2;
              vfx_particle_curl = 1.0;
              vfx_particle_phase = 1.5;
              vfx_particle_speed = 10.0;
            };
            
            # Scroll settings
            scroll_animation_length = 0.3;
            
            # Window settings
            padding = {
              top = 0;
              bottom = 0;
              left = 0;
              right = 0;
            };
            
            # Input settings
            input_macos_alt_is_meta = false;
            
            # Confirm quit
            confirm_quit = true;
            
            # Remember window size
            remember_window_size = true;
            
            # Profiler
            profiler = false;
            
            # Vsync
            vsync = true;
            
            # Multigrid
            multigrid = true;
            
            # Fork
            fork = false;
            
            # Frame decoration
            frame = "full";
            
            # Titlebar
            titlebar = true;
            
            # Tabs
            tabs = true;
            
            # Refresh rate
            refresh_rate = 60;
            
            # Refresh rate idle
            refresh_rate_idle = 5;
            
            # No idle
            no_idle = false;
            
            # Maximized
            maximized = false;
            
            # Fullscreen
            fullscreen = false;
            
            # Borderless
            borderless = false;
          }
          cfg.settings
        ]);
        
        # Desktop entry for Neovide
        ".local/share/applications/neovide.desktop".text = ''
          [Desktop Entry]
          Type=Application
          Name=Neovide
          Comment=No Nonsense Neovim Client in Rust
          Exec=${cfg.package}/bin/neovide %F
          Icon=neovide
          Terminal=false
          Categories=Development;TextEditor;
          StartupWMClass=neovide
          MimeType=text/plain;text/x-makefile;text/x-c++hdr;text/x-c++src;text/x-chdr;text/x-csrc;text/x-java;text/x-moc;text/x-pascal;text/x-tcl;text/x-tex;application/x-shellscript;text/x-c;text/x-c++;
          StartupNotify=true
        '';
      };
    };
  };
}
###############################################################################
# Neovide Configuration for Development
# Neovide is configured via Neovim Lua, not external config files
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.dev.nvim;
  inherit (config.shared) username;
in {
  ###########################################################################
  # Neovide Package Installation and Configuration
  ###########################################################################
  config = lib.mkIf (cfg.enable && cfg.neovide) {
    users.users.${username}.maid = {
      packages = with pkgs; [
        neovide
      ];

      file.xdg_config."nvim/lua/config/neovide.lua".text = ''
        -- Neovide-specific configuration
        -- Only runs when inside Neovide GUI

        if not vim.g.neovide then
          return
        end

        -- Font configuration
        vim.o.guifont = "Fast_Mono:h14"

        -- Neovide-specific options
        vim.g.neovide_scale_factor = 1.0
        vim.g.neovide_transparency = 0.0
        vim.g.neovide_window_blurred = false

        -- Cursor animation
        vim.g.neovide_cursor_animation_length = 0.1
        vim.g.neovide_cursor_trail_size = 0.8
        vim.g.neovide_cursor_antialiasing = true
        vim.g.neovide_cursor_animate_in_insert_mode = true
        vim.g.neovide_cursor_animate_command_line = true

        -- Cursor particles
        vim.g.neovide_cursor_vfx_mode = "railgun"
        vim.g.neovide_cursor_vfx_opacity = 200.0
        vim.g.neovide_cursor_vfx_particle_density = 10.0
        vim.g.neovide_cursor_vfx_particle_lifetime = 1.2

        -- Scroll animation
        vim.g.neovide_scroll_animation_length = 0.3

        -- Window padding
        vim.g.neovide_padding_top = 0
        vim.g.neovide_padding_bottom = 0
        vim.g.neovide_padding_right = 0
        vim.g.neovide_padding_left = 0

        -- Remember window size
        vim.g.neovide_remember_window_size = true

        -- Confirm quit
        vim.g.neovide_confirm_quit = true

        -- Frame rate
        vim.g.neovide_refresh_rate = 60
        vim.g.neovide_refresh_rate_idle = 5

        -- Input settings
        vim.g.neovide_input_macos_alt_is_meta = false

        -- Fullscreen
        vim.g.neovide_fullscreen = false

        -- Theme
        vim.g.neovide_theme = "auto"

        -- Touch settings
        vim.g.neovide_touch_deadzone = 6.0
        vim.g.neovide_touch_drag_timeout = 0.17


      '';
    };
  };
}

# Shared Neovim configuration exports for all systems
# This library provides base configuration that can be used by Darwin and NixOS
{
  # Plugin list - array of plugin URLs
  plugins = import ./plugins.nix;

  # Core vim settings - returns Lua string
  settings = import ./settings.nix;

  # Keymaps - returns Lua string
  keymaps = import ./keymaps.nix;

  # Theme configuration - minimalist biophilic with dopamine accents
  theme = import ./theme.nix;
}

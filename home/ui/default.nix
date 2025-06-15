###############################################################################
# UI Modules Collection (Maid)
# Imports all ui-related Home modules
###############################################################################
{helpers, ...}: {
  imports = [
    ./ags.nix
    ./cursor.nix
    ./fonts.nix
    ./foot.nix
    ./gtk.nix
    ./hyprland
    ./mako.nix
    ./wallust.nix
    ./wayland.nix
  ];
}

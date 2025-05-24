{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # AGS and core Astal
    ags
    astal.gjs
    astal.io
    astal.astal3
    
    # Hyprland support
    astal.hyprland
    
    # Development tools
    gobject-introspection
  ];
  
  shellHook = ''
    echo "AGS development environment (nixpkgs version)"
    echo "AGS version: $(ags --version)"
    echo "Available modules: gjs, io, astal3, hyprland"
    echo "Run: ags run app.tsx"
  '';
} 
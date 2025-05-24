{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    ags
    astal.gjs
    astal.io
    astal.astal3
    astal.astal4
  ];
  
  shellHook = ''
    echo "AGS development environment with Astal modules loaded"
    echo "You can now use: ags run app.tsx"
    echo "Using hyprctl commands (no native Hyprland bindings needed)"
  '';
} 
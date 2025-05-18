#!/bin/bash

# Make sure the script exits on any error
set -e

echo "Applying Fast Fonts configuration..."

# Git status before changes
echo "Git status before changes:"
git status

# Reset any failed changes
echo "Resetting any failed changes..."
git checkout -- flake.nix home/hosts/y0usaf-desktop/default.nix home/hosts/y0usaf-laptop/default.nix

# Re-apply our changes
echo "Re-applying changes to flake.nix..."
sed -i '/deepin-dark-xcursor.url = "path:\/home\/y0usaf\/nixos\/lib\/resources\/deepin-dark-xcursor";/a \    fast-fonts.url = "path:\/home\/y0usaf\/nixos\/lib\/resources\/fast-fonts";' flake.nix

echo "Adding fastFonts to overlays in flake.nix..."
sed -i '/inherit (inputs.uv2nix.packages.\${system}) uv2nix;/a \          fastFonts = inputs.fast-fonts.fastFontSource;' flake.nix

echo "Adding fast-fonts to commonSpecialArgs in flake.nix..."
sed -i '/disko = inputs.disko;/a \      fast-fonts = inputs.fast-fonts;' flake.nix

echo "Updating desktop configuration to use Fast Mono..."
sed -i 's/package = pkgs.nerd-fonts.iosevka-term-slab;/package = pkgs.fastFonts;/' home/hosts/y0usaf-desktop/default.nix
sed -i 's/name = "IosevkaTermSlab Nerd Font Mono";/name = "Fast Mono";/' home/hosts/y0usaf-desktop/default.nix

echo "Updating laptop configuration to use Fast Mono..."
sed -i 's/package = pkgs.nerd-fonts.iosevka-term-slab;/package = pkgs.fastFonts;/' home/hosts/y0usaf-laptop/default.nix
sed -i 's/name = "IosevkaTermSlab Nerd Font Mono";/name = "Fast Mono";/' home/hosts/y0usaf-laptop/default.nix

# Git status after changes
echo "Git status after changes:"
git status

echo "Done! You can now apply the changes with 'nh os switch'"
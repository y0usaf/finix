#!/usr/bin/env bash
# Test script to check Nix syntax

echo "Testing flake syntax..."
nix flake check --show-trace 2>&1

echo "Testing AGS module syntax..."
nix-instantiate --eval --expr 'import ./hjem/ui/ags.nix { config = {}; pkgs = import <nixpkgs> {}; lib = (import <nixpkgs> {}).lib; }' 2>&1

echo "Testing host configuration syntax..."
nix-instantiate --eval --expr 'import ./hosts/y0usaf-desktop/default.nix { pkgs = import <nixpkgs> {}; lib = (import <nixpkgs> {}).lib; }' 2>&1
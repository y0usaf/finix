{lib, ...}: let
  # Get all .nix files in this directory
  files =
    lib.filterAttrs (n: v: v == "regular" && lib.hasSuffix ".nix" n && n != "default.nix")
    (builtins.readDir ./.);

  # Convert filenames to paths
  paths = map (name: ./. + "/${name}") (builtins.attrNames files);
in {
  imports = paths;
}

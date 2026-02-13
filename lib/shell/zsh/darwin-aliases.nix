# Darwin/macOS-specific aliases
_: {
  # nix-darwin switch
  nds = "nh darwin switch";

  # Darwin build timing
  buildtime = "time (nix build \"\${NH_DARWIN_FLAKE}#darwinConfigurations.\${HOST}.system\" --option eval-cache false)";
}

# Darwin/macOS-specific aliases
{}: {
  # nix-darwin switch
  nds = "nh darwin switch";

  # Darwin build timing
  buildtime = "time (nix build .#darwinConfigurations.y0usaf-macbook.system --option eval-cache false)";
}

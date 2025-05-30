###############################################################################
# Formatter Configuration
# Code formatting setup for the flake
###############################################################################
inputs: let
  ## System Configuration
  system = "x86_64-linux";
  
  ## Package Configuration
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [
      (final: prev: {
        fastFonts = inputs.fast-fonts.packages.${system}.default;
      })
    ];
    config.allowUnfree = true;
    config.cudaSupport = true;
  };
in {
  ## Formatter Setup
  formatter.${system} = pkgs.alejandra;
}
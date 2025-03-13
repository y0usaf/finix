{
  config,
  lib,
  pkgs,
  profile,
  ...
}: {
  # Install CUDA development tools
  home.packages = with pkgs; [
    cudaPackages.cudatoolkit
  ];

  # Set environment variables
  home.sessionVariables = {
    CUDA_PATH = "${pkgs.cudaPackages.cudatoolkit}";
  };
}

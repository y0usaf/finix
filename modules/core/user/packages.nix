{
  pkgs,
  flakeInputs,
  ...
}: {
  environment.systemPackages = [
    pkgs.wget
    pkgs.cachix
    pkgs.unzip
    pkgs.lsd
    pkgs.tree
    pkgs.psmisc
    pkgs.lm_sensors
    pkgs.fzf
    pkgs.ripgrep
    flakeInputs.strictix.packages."${pkgs.stdenv.hostPlatform.system}".default
    pkgs.alejandra
    pkgs.statix
    pkgs.deadnix
  ];
}

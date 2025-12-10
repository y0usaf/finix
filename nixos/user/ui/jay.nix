{
  flakeInputs,
  system,
  ...
}: {
  environment.systemPackages = [
    flakeInputs.jay.packages.${system}.jay
  ];
}

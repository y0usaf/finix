{
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = [
    inputs.strictix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}

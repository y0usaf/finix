{
  config,
  pkgs,
  flakeInputs,
  ...
}: {
  environment.systemPackages = [
    flakeInputs.linear-cli.packages.${pkgs.stdenv.hostPlatform.system}.linear
    pkgs.libsecret
  ];

  manzil.users."${config.user.name}".files.".config/linear/linear.toml".source = (pkgs.formats.toml {}).generate "linear-cli-config" {
    workspace = "cook-unity";
  };
}

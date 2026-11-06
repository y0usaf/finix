{
  pkgs,
  inputPackages,
  ...
}: {
  environment.systemPackages = [
    inputPackages.linear-cli.linear
    pkgs.libsecret
  ];

  user.files.".config/linear/linear.toml".source = (pkgs.formats.toml {}).generate "linear-cli-config" {
    workspace = "cook-unity";
  };
}

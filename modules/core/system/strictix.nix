{
  config,
  pkgs,
  flakeInputs,
  ...
}: {
  environment.systemPackages = [
    flakeInputs.strictix.packages."${pkgs.stdenv.hostPlatform.system}".default
  ];

  bayt.users."${config.user.name}".files.".config/strictix/config.toml" = {
    source = (pkgs.formats.toml {}).generate "strictix-config" {
      enabled = [
        "single_use_let"
        "unused_pattern_param"
      ];
      lints.unused_pattern_param.remove_ellipsis = true;
    };
  };
}

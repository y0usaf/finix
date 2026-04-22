{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  cfg = config.user.tools.linear-cli;
  tomlFormat = pkgs.formats.toml {};
  linearCliPkg = flakeInputs.linear-cli.packages."${pkgs.stdenv.hostPlatform.system}".default;
in {
  options.user.tools.linear-cli = {
    enable = lib.mkEnableOption "Linear CLI";

    package = lib.mkOption {
      type = lib.types.package;
      default = linearCliPkg;
      description = "Linear CLI package to install.";
    };

    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = {};
      description = "Linear CLI settings written to ~/.config/linear/linear.toml.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
      pkgs.libsecret
    ];

    bayt.users."${config.user.name}".files = lib.optionalAttrs (builtins.length (builtins.attrNames cfg.settings) > 0) {
      ".config/linear/linear.toml" = {
        source = tomlFormat.generate "linear-cli-config" cfg.settings;
      };
    };
  };
}

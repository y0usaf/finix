{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.dev.work.gws = {
    enable = lib.mkEnableOption "Google Workspace CLI";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.gws;
      description = "gws CLI package to install.";
    };
  };

  config = lib.mkIf config.user.dev.work.gws.enable {
    environment.systemPackages = [
      config.user.dev.work.gws.package
    ];
  };
}

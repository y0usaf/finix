{
  lib,
  pkgs,
  ...
}: {
  options.user.shell.zellij = {
    enable = lib.mkEnableOption "zellij terminal multiplexer";

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.zellij;
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
    };

    performanceMode = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    themeConfig = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
  };
}

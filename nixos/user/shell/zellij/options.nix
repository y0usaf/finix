{lib, ...}: {
  options.user.shell.zellij = {
    enable = lib.mkEnableOption "zellij terminal multiplexer";

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Automatically start Zellij session on shell startup";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = lib.mkDefault "zellij";
      description = "The Zellij package to use";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Additional settings for Zellij configuration";
    };

    themeConfig = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Theme configuration for Zellij";
    };

    performanceMode = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Optimize configuration for faster startup times";
    };
  };
}

{
  lib,
  pkgs ? null,
  ...
}: {
  options.user.shell.zellij = {
    enable = lib.mkEnableOption "zellij terminal multiplexer";

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Automatically start Zellij session on shell startup";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default =
        if pkgs != null
        then pkgs.zellij
        else lib.mkDefault "zellij";
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

    zjstatus = {
      enable = lib.mkEnableOption "zjstatus plugin for zellij";

      layout = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Layout configuration for zjstatus";
      };

      maxLength = lib.mkOption {
        type = lib.types.int;
        default = 0;
        description = "Max length for zjstatus hints";
      };

      pipeName = lib.mkOption {
        type = lib.types.str;
        default = "zjstatus_hints";
        description = "Pipe name for zjstatus hints";
      };
    };

    zjstatusHints = {
      enable = lib.mkEnableOption "zjstatus-hints plugin for zellij";

      maxLength = lib.mkOption {
        type = lib.types.int;
        default = 0;
        description = "Max length for zjstatus hints";
      };

      pipeName = lib.mkOption {
        type = lib.types.str;
        default = "zjstatus_hints";
        description = "Pipe name for zjstatus hints";
      };
    };
  };
}
